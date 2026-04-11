ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# #region agent log
begin
  require "json"
  _agent_log = "/Users/chankokpan/Documents/second_hand_marketplace/CSCI3100-Group-23-Project-/.cursor/debug-6aeaf5.log"
  File.open(_agent_log, "a") do |f|
    f.puts(JSON.generate({ sessionId: "6aeaf5", hypothesisId: "B", location: "config/boot.rb", message: "boot.rb finished (bundler+bootsnap)", data: {}, timestamp: (Time.now.to_f * 1000).to_i, runId: ENV["DEBUG_RUN_ID"] }))
  end
rescue StandardError
end
# #endregion
