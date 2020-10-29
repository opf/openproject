require 'bundler/setup'
require 'rake/testtask'

desc 'Test the representable gem.'
task :default => :test

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/**/*_test.rb']
  test.verbose = true
end

Rake::TestTask.new(:dtest) do |test|
  test.libs << 'test-with-deprecations'
  test.test_files = FileList['test-with-deprecations/**/*_test.rb']
  test.verbose = true
end