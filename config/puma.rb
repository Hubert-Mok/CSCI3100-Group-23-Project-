# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.
#
# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# You can control the number of workers using ENV["WEB_CONCURRENCY"]. You
# should only set this value when you want to run 2 or more workers. The
# default is already 1. You can set it to `auto` to automatically start a worker
# for each available processor.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# #region agent log
begin
  require "json"
  _agent_log = "/Users/chankokpan/Documents/second_hand_marketplace/CSCI3100-Group-23-Project-/.cursor/debug-6aeaf5.log"
  _p = ENV.fetch("PORT", 3000)
  File.open(_agent_log, "a") do |f|
    f.puts(JSON.generate({ sessionId: "6aeaf5", hypothesisId: "C", location: "config/puma.rb", message: "Puma port configured", data: { port: _p.to_s, port_env: ENV["PORT"] }, timestamp: (Time.now.to_f * 1000).to_i, runId: ENV["DEBUG_RUN_ID"] }))
  end
rescue StandardError
end
# #endregion

on_booted do
  # #region agent log
  begin
    require "json"
    _agent_log = "/Users/chankokpan/Documents/second_hand_marketplace/CSCI3100-Group-23-Project-/.cursor/debug-6aeaf5.log"
    File.open(_agent_log, "a") do |f|
      f.puts(JSON.generate({ sessionId: "6aeaf5", hypothesisId: "A", location: "config/puma.rb:on_booted", message: "Puma on_booted fired (server should accept connections)", data: {}, timestamp: (Time.now.to_f * 1000).to_i, runId: ENV["DEBUG_RUN_ID"] }))
    end
  rescue StandardError
  end
  # #endregion
end

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments.
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
