require 'bundler'
Bundler::GemHelper.install_tasks

desc 'Run all tests by default'
task :default => :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["--color", '--format doc', '--require spec_helper']
end