# frozen_string_literal: true

require 'bundler'
Bundler.setup

require 'rake'
require 'rspec/core/rake_task'

task default: %i[spec rubocop]

desc 'Run all rspec files'
RSpec::Core::RakeTask.new('spec') do |c|
  c.rspec_opts = '-t ~unresolved'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new
