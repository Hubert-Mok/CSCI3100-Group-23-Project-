class ApplicationJob < ActiveJob::Base
  DEBUG_LOG_PATH = Rails.root.join(".cursor", "debug-90ad6c.log")

  around_perform do |job, block|
    if job.class.name == "ActionMailer::MailDeliveryJob"
      run_id = SecureRandom.hex(6)
      # #region agent log
      begin
        File.open(DEBUG_LOG_PATH, "a") do |f|
          f.puts({
            sessionId: "90ad6c",
            runId: run_id,
            hypothesisId: "H5",
            location: "app/jobs/application_job.rb:around_perform",
            message: "MailDeliveryJob perform started",
            data: { job_id: job.job_id, queue_name: job.queue_name },
            timestamp: (Time.now.to_f * 1000).to_i
          }.to_json)
        end
      rescue StandardError
      end
      # #endregion

      block.call

      # #region agent log
      begin
        File.open(DEBUG_LOG_PATH, "a") do |f|
          f.puts({
            sessionId: "90ad6c",
            runId: run_id,
            hypothesisId: "H5",
            location: "app/jobs/application_job.rb:around_perform",
            message: "MailDeliveryJob perform completed",
            data: { job_id: job.job_id, queue_name: job.queue_name },
            timestamp: (Time.now.to_f * 1000).to_i
          }.to_json)
        end
      rescue StandardError
      end
      # #endregion
    else
      block.call
    end
  rescue StandardError => e
    # #region agent log
    begin
      File.open(DEBUG_LOG_PATH, "a") do |f|
        f.puts({
          sessionId: "90ad6c",
          runId: (defined?(run_id) && run_id) || SecureRandom.hex(6),
          hypothesisId: "H5",
          location: "app/jobs/application_job.rb:around_perform",
          message: "MailDeliveryJob perform failed",
          data: { job_id: job.job_id, error_class: e.class.name, error_message: e.message.to_s[0, 200] },
          timestamp: (Time.now.to_f * 1000).to_i
        }.to_json)
      end
    rescue StandardError
    end
    # #endregion
    raise
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
