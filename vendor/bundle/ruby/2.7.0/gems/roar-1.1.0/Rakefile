require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList.new('test/**/*_test.rb') do |fl|
    fl.exclude('test/integration/**') if RUBY_VERSION < '2.2.2'
  end
  test.verbose = true
end
