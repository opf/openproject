# frozen_string_literal: true

raise "Coverage must start before Rails loads" if defined?(Rails::Application)

require "securerandom"
require_relative "rspec_coverage_config"

RSpecCoverage.configure
worker = "#{ENV.fetch('TEST_ENV_NUMBER', 'serial')}-#{SecureRandom.uuid}"
SimpleCov.command_name("#{ENV.fetch('COVERAGE_SUITE', 'RSpec')} #{worker}")
SimpleCov.coverage_dir(File.join(ENV.fetch("COVERAGE_DIR", "coverage/rspec"), "workers", worker))
SimpleCov.start
