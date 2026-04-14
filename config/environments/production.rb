require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Durable uploads: Azure Blob when AZURE_STORAGE_* are set (see infra/core.bicep); else ephemeral Disk.
  config.active_storage.service = if ENV["AZURE_STORAGE_ACCOUNT_NAME"].present? && ENV["AZURE_STORAGE_ACCESS_KEY"].present?
    :azure
  else
    :local
  end

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Raise delivery errors in production so failures surface in logs/error tracking.
  config.action_mailer.raise_delivery_errors = true

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "cuhk-marketplace.herokuapp.com"), protocol: "https" }

  # Default: Azure Communication Services Email SMTP (STARTTLS on 587). See infra/README.md.
  # For implicit TLS on 465 (e.g. Gmail), set SMTP_TLS_IMPLICIT=true and SMTP_ADDRESS=smtp.gmail.com.
  config.action_mailer.delivery_method = :smtp
  smtp_implicit_tls = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SMTP_TLS_IMPLICIT", "false"))
  default_smtp_port = smtp_implicit_tls ? "465" : "587"
  smtp_address = ENV.fetch("SMTP_ADDRESS", "smtp.azurecomm.net")
  # Azure Communication Services (smtp.azurecomm.net) accepts AUTH LOGIN only; AUTH PLAIN returns 504 5.7.4.
  smtp_authentication = if ENV["SMTP_AUTHENTICATION"].present?
    ENV["SMTP_AUTHENTICATION"].to_sym
  else
    smtp_address.include?("azurecomm.net") ? :login : :plain
  end
  config.action_mailer.smtp_settings = {
    address: smtp_address,
    port: ENV.fetch("SMTP_PORT", default_smtp_port).to_i,
    user_name: ENV.fetch("SMTP_USERNAME"),
    password: ENV.fetch("SMTP_PASSWORD"),
    authentication: smtp_authentication
  }.tap do |settings|
    if smtp_implicit_tls
      settings[:tls] = true
    else
      settings[:enable_starttls_auto] = true
    end
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
