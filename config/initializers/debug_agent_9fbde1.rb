# frozen_string_literal: true

require "json"
require "fileutils"

# Debug session 9fbde1: Action Mailer / SMTP (ACS) delivery instrumentation.
# Disable: DEBUG_AGENT_9FBDE1=0
# NDJSON: Rails.root/.cursor/debug-9fbde1.log (also mirrored to Rails.logger for Azure Log stream)

# #region agent log
module DebugAgent9fbde1
  LOG_PATH = File.expand_path("../../.cursor/debug-9fbde1.log", __dir__).freeze

  def self.enabled?
    ENV.fetch("DEBUG_AGENT_9FBDE1", "1") == "1"
  end

  def self.log(hypothesis_id:, location:, message:, data: {})
    return unless enabled?

    payload = {
      sessionId: "9fbde1",
      hypothesisId: hypothesis_id,
      location: location,
      message: message,
      data: data,
      timestamp: (Time.now.to_f * 1000).to_i
    }
    line = JSON.generate(payload)
    FileUtils.mkdir_p(File.dirname(LOG_PATH))
    File.open(LOG_PATH, "a") { |f| f.puts(line) }
    Rails.logger.warn("[debug_9fbde1] #{line}")
  rescue StandardError => e
    Rails.logger.warn("[debug_9fbde1] log failed: #{e.class}: #{e.message}")
  end
end

Rails.application.config.after_initialize do
  next unless DebugAgent9fbde1.enabled?
  next if Rails.application.config.x.debug_agent_9fbde1_installed

  Rails.application.config.x.debug_agent_9fbde1_installed = true

  if Rails.env.production?
    mf = ENV["MAILER_FROM"].to_s
    su = ENV["SMTP_USERNAME"].to_s
    sp = ENV["SMTP_PASSWORD"].to_s
    DebugAgent9fbde1.log(
      hypothesis_id: "H3",
      location: "debug_agent_9fbde1.rb:after_initialize",
      message: "mail_config_snapshot",
      data: {
        smtp_address: ActionMailer::Base.smtp_settings[:address].to_s,
        smtp_port: ActionMailer::Base.smtp_settings[:port].to_i,
        smtp_username_length: su.length,
        smtp_password_present: sp.present?,
        smtp_password_byte_length: sp.bytesize,
        smtp_username_trims_differ: su != su.strip,
        smtp_password_trims_differ: sp != sp.strip,
        smtp_username_email_at_azurecomm: su.match?(/\A[^@\s]+@[^@\s]+\.azurecomm\.net\z/i),
        smtp_username_looks_like_entra_client_id: su.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i),
        mailer_from_present: mf.present?,
        mailer_from_domain_suffix: mf.include?("@") ? mf.split("@", 2).last.to_s[0, 120] : "",
        enable_starttls_auto: ActionMailer::Base.smtp_settings[:enable_starttls_auto],
        smtp_authentication: ActionMailer::Base.smtp_settings[:authentication].to_s,
        smtp_tls_implicit: ActiveModel::Type::Boolean.new.cast(ENV.fetch("SMTP_TLS_IMPLICIT", "false"))
      }
    )
  end

  ActiveSupport::Notifications.subscribe("deliver.action_mailer") do |_name, _start, _finish, _id, payload|
    mailer = payload[:mailer]
    next unless mailer

    DebugAgent9fbde1.log(
      hypothesis_id: "H1",
      location: "AS::Notifications deliver.action_mailer",
      message: "mail_delivered_ok",
      data: {
        mailer_class: mailer.class.name,
        action: payload[:action].to_s
      }
    )
  end

  ActiveSupport::Notifications.subscribe("enqueue.active_job") do |_name, _start, _finish, _id, payload|
    job = payload[:job]
    next unless job

    jc = job.class.name
    next unless jc == "ActionMailer::MailDeliveryJob" || jc.include?("MailDeliveryJob")

    args = job.arguments || []
    DebugAgent9fbde1.log(
      hypothesis_id: "H4",
      location: "AS::Notifications enqueue.active_job",
      message: "mail_delivery_job_enqueued",
      data: {
        job_class: jc,
        mailer_class: args[0].to_s,
        mailer_action: args[1].to_s,
        adapter: payload[:adapter].to_s
      }
    )
  end
end
# #endregion
