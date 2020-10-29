require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task default: [:spec, :build]

desc "Load iCalendar in IRB"
task :console do
  require 'irb'
  require 'irb/completion'
  $:.unshift File.join(File.dirname(__FILE__), 'lib')
  require 'icalendar'
  ARGV.clear
  IRB.start
end
