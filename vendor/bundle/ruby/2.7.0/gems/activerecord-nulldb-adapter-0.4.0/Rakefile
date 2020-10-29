require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

require 'bundler/gem_tasks'

RSpec::Core::RakeTask.new(:spec)
task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "LICENSE", "lib/**/*.rb")
end
