require "bundler/setup"
require "drunker"
require "timecop"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

module Drunker
  class Aggregator
    class Test < Base; end
  end
end
