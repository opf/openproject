require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/extensiontask'
require 'rake/testtask'

task default: :test

Rake::ExtensionTask.new('rinku') # defines compile task

Rake::TestTask.new(test: :compile) do |t|
  t.test_files = FileList['test/*_test.rb']
end
