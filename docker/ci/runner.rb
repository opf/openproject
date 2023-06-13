#!/usr/bin/env ruby

require 'rubygems'
require 'test_queue'
require 'bundler'
Bundler.setup(:default, :development, :test)
require_relative "../../config/environment.rb"
require "test_queue/runner/rspec"

class MyAppTestRunner < TestQueue::Runner::RSpec
  def after_fork(num)
    # Use separate mysql database (we assume it exists and has the right schema already)
    p [:num, num]
    p ActiveRecord::Base.configurations
    p [:yoh, ActiveRecord::Base.configurations.configs_for(env_name: 'test', name: 'primary').database]
    ActiveRecord::Base.configurations.configs_for(env_name: 'test', name: 'primary').database << num.to_s
    ActiveRecord::Base.establish_connection(:test)
  end

  def prepare(concurrency)
  end

  def around_filter(suite)
    p suite
    # $stats.timing("test.#{suite}.runtime") do
    #   yield
    # end
  end
end

MyAppTestRunner.new.execute