require "bundler/gem_tasks"
require "rake/testtask"

RAILS_VERSION = ENV['RAILS_VERSION'] || '5.0'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/rails#{RAILS_VERSION}/**/*_test.rb"]
end

task :default => :test
