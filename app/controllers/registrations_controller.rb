class RegistrationsController < ApplicationController
  def new
    redirect_to root_path, notice: "You are already signed in." if logged_in?
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      raw_token = @user.generate_email_verification_token!
      # #region agent log
      begin
        File.open("/rails/.cursor/debug-589197.log", "a") do |f|
          f.puts({ sessionId: "589197", hypothesisId: "C-verify", runId: "post-fix",
            location: "registrations_controller.rb:create",
            message: "post-fix: delivery method and API key check",
            data: { delivery_method: ActionMailer::Base.delivery_method.to_s,
                    smtp_address: ActionMailer::Base.smtp_settings&.dig(:address),
                    smtp_port: ActionMailer::Base.smtp_settings&.dig(:port),
                    smtp_username_present: ENV["SMTP_USERNAME"].present?,
                    recipient: @user.email },
            timestamp: Time.now.to_i * 1000 }.to_json)
        end
      rescue => e; Rails.logger.error("DBG ERR: #{e}"); end
      # #endregion
      begin
        UserMailer.email_verification(@user, raw_token).deliver_now
        # #region agent log
        File.open("/rails/.cursor/debug-589197.log", "a") do |f|
          f.puts({ sessionId: "589197", hypothesisId: "C-verify", runId: "post-fix",
            location: "registrations_controller.rb:after_deliver",
            message: "post-fix: deliver_now SUCCEEDED",
            data: { recipient: @user.email }, timestamp: Time.now.to_i * 1000 }.to_json)
        end
        # #endregion
      rescue => err
        # #region agent log
        File.open("/rails/.cursor/debug-589197.log", "a") do |f|
          f.puts({ sessionId: "589197", hypothesisId: "C-verify", runId: "post-fix",
            location: "registrations_controller.rb:rescue",
            message: "post-fix: deliver_now FAILED",
            data: { error_class: err.class.to_s, error_msg: err.message.to_s[0..400] },
            timestamp: Time.now.to_i * 1000 }.to_json)
        end
        # #endregion
        Rails.logger.error("MAIL ERROR: #{err.class}: #{err.message}")
      end
      redirect_to new_email_verification_path(email: @user.email),
        notice: "Account created! Please check your CUHK email to verify your account before signing in."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.expect(user: [ :email, :password, :password_confirmation, :cuhk_id, :username, :college_affiliation ])
  end
end
