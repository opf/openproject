require 'spec/rake/spectask'
require 'rake/rdoctask'

desc 'Default: run all specs'
task :default => :spec

desc 'Run all application-specific specs'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.rcov = true
end

desc "Report code statistics (KLOCs, etc) from the application"
task :stats do
  RAILS_ROOT = File.dirname(__FILE__)
  STATS_DIRECTORIES = [
    %w(Libraries  lib/),
    %w(Specs      spec/),
  ].collect { |name, dir| [ name, "#{RAILS_ROOT}/#{dir}" ] }.select { |name, dir| File.directory?(dir) }
  require 'code_statistics'
  CodeStatistics.new(*STATS_DIRECTORIES).to_s
end

namespace :doc do
  desc 'Generate documentation for the assert_request plugin.'
  Rake::RDocTask.new(:plugin) do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = 'Gravatar Rails Plugin'
    rdoc.options << '--line-numbers' << '--inline-source' << '--accessor' << 'cattr_accessor=rw'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
end
