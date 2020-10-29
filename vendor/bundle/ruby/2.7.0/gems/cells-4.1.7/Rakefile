require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/*_test.rb'
  test.verbose = true
  # Ruby built-in warnings contain way too much noise to be useful. Consider turning them on again when the following issues are accepted in ruby:
  # * https://bugs.ruby-lang.org/issues/10967 (remove warning: private attribute?)
  # * https://bugs.ruby-lang.org/issues/12299 (customized warning handling)
  test.warning = false
end

# Rake::TestTask.new(:rails) do |test|
#   test.libs << 'test/rails'
#   test.test_files = FileList['test/rails4.2/*_test.rb']
#   test.verbose = true
# end

# rails_task = Rake::Task["rails"]
# test_task = Rake::Task["test"]
# default_task.enhance { test_task.invoke }
# default_task.enhance { rails_task.invoke }
