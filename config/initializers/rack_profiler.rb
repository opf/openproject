# frozen_string_literal: true

if Rails.env.development? && ENV['OPENPROJECT_RACK_PROFILER_ENABLED']
  require "rack-mini-profiler"
  require 'flamegraph'
  require 'stackprof'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rack::MiniProfiler.config.position = 'bottom-right'
end
