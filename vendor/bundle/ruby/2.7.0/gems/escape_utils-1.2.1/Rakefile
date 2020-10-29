require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
end

task :default => :test

gem 'rake-compiler', '>= 0.7.5'
require "rake/extensiontask"

Rake::ExtensionTask.new('escape_utils') do |ext|
  ext.cross_compile = true
  ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']

  ext.lib_dir = File.join 'lib', 'escape_utils'
end

Rake::Task[:test].prerequisites << :compile
