# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

# #region agent log
begin
  require "json"
  _agent_log = "/Users/chankokpan/Documents/second_hand_marketplace/CSCI3100-Group-23-Project-/.cursor/debug-6aeaf5.log"
  File.open(_agent_log, "a") do |f|
    f.puts(JSON.generate({ sessionId: "6aeaf5", hypothesisId: "B", location: "config/environment.rb", message: "Rails.application.initialize! completed", data: {}, timestamp: (Time.now.to_f * 1000).to_i, runId: ENV["DEBUG_RUN_ID"] }))
  end
rescue StandardError
end
# #endregion
