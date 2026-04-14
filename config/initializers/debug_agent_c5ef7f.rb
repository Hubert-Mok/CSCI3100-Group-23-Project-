# frozen_string_literal: true

require "json"
require "fileutils"

# Debug session c5ef7f: Active Storage / Azure 500 instrumentation.
# Disable: DEBUG_AGENT_C5EF7F=0
# Log file: Rails root .cursor/debug-c5ef7f.log (NDJSON)

# #region agent log
module DebugAgentC5ef7f
  LOG_PATH = File.expand_path("../../.cursor/debug-c5ef7f.log", __dir__).freeze

  def self.enabled?
    ENV.fetch("DEBUG_AGENT_C5EF7F", "1") == "1"
  end

  def self.log(hypothesis_id:, location:, message:, data: {})
    return unless enabled?

    payload = {
      sessionId: "c5ef7f",
      hypothesisId: hypothesis_id,
      location: location,
      message: message,
      data: data,
      timestamp: (Time.now.to_f * 1000).to_i
    }
    FileUtils.mkdir_p(File.dirname(LOG_PATH))
    line = JSON.generate(payload)
    File.open(LOG_PATH, "a") { |f| f.puts(line) }
    Rails.logger.warn("[debug_c5ef7f] #{line}")
  rescue StandardError => e
    Rails.logger.warn("[debug_c5ef7f] log failed: #{e.class}: #{e.message}")
  end

  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      path = env["PATH_INFO"].to_s
      unless path.include?("/rails/active_storage/")
        return @app.call(env)
      end

      svc = Rails.application.config.active_storage.service
      DebugAgentC5ef7f.log(
        hypothesis_id: "H3",
        location: "DebugAgentC5ef7f::Middleware#call",
        message: "active_storage_request_start",
        data: {
          path: path,
          configured_service: svc.to_s,
          azure_account_present: ENV["AZURE_STORAGE_ACCOUNT_NAME"].present?,
          azure_key_present: ENV["AZURE_STORAGE_ACCESS_KEY"].present?,
          azure_container: ENV["AZURE_STORAGE_CONTAINER"].to_s
        }
      )

      status, headers, body = @app.call(env)
      code = status.to_i
      if code >= 400
        DebugAgentC5ef7f.log(
          hypothesis_id: "H-http",
          location: "DebugAgentC5ef7f::Middleware#call",
          message: "active_storage_error_status",
          data: { path: path, status: code }
        )
      end
      [status, headers, body]
    rescue StandardError => e
      DebugAgentC5ef7f.log(
        hypothesis_id: "H1-H5",
        location: "DebugAgentC5ef7f::Middleware#call",
        message: "active_storage_exception",
        data: {
          path: path,
          exception_class: e.class.name,
          exception_message: e.message.to_s[0, 800],
          backtrace_preview: Array(e.backtrace).first(12)
        }
      )
      raise
    end
  end
end

Rails.application.config.after_initialize do
  next unless DebugAgentC5ef7f.enabled?
  next if Rails.application.config.x.debug_agent_c5ef7f_installed

  Rails.application.config.x.debug_agent_c5ef7f_installed = true

  Rails.application.middleware.unshift(DebugAgentC5ef7f::Middleware)

  ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
    payload = args.last
    controller = payload[:controller]
    next unless controller.is_a?(Class) && controller.name.to_s.include?("ActiveStorage")

    ex = payload[:exception_object]
    if ex.nil? && payload[:exception].is_a?(Array)
      DebugAgentC5ef7f.log(
        hypothesis_id: "H1-H5",
        location: "AS::Notifications process_action",
        message: "active_storage_process_action_exception_array",
        data: {
          controller: controller.name,
          action: payload[:action].to_s,
          exception: payload[:exception]
        }
      )
    elsif ex
      DebugAgentC5ef7f.log(
        hypothesis_id: "H1-H5",
        location: "AS::Notifications process_action",
        message: "active_storage_process_action_exception",
        data: {
          controller: controller.name,
          action: payload[:action].to_s,
          exception_class: ex.class.name,
          exception_message: ex.message.to_s[0, 800],
          backtrace_preview: Array(ex.backtrace).first(12)
        }
      )
    end
  end
end
# #endregion
