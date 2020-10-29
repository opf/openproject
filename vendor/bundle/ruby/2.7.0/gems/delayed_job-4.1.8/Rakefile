require 'bundler/setup'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
desc 'Run the specs'
RSpec::Core::RakeTask.new do |r|
  r.verbose = false
end

task :test => :spec

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task :default => [:spec, :rubocop]
