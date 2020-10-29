require 'rake/testtask'
require 'bundler/gem_tasks'

task default: :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end
