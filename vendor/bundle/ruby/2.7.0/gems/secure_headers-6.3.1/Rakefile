#!/usr/bin/env rake
# frozen_string_literal: true
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "net/http"
require "net/https"

RSpec::Core::RakeTask.new

begin
  require "rdoc/task"
rescue LoadError
  require "rdoc/rdoc"
  require "rake/rdoctask"
  RDoc::Task = Rake::RDocTask
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  task(:rubocop) { $stderr.puts "RuboCop is disabled" }
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "SecureHeaders"
  rdoc.options << "--line-numbers"
  rdoc.rdoc_files.include("lib/**/*.rb")
end

task default: [:spec, :rubocop]
