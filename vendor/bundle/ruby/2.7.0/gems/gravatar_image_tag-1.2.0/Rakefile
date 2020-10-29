require 'rake'
require 'rspec/core/rake_task'

begin
  AUTHOR   = "Michael Deering"
  EMAIL    = "mdeering@mdeering.com"
  GEM      = "gravatar_image_tag"
  HOMEPAGE = "http://github.com/mdeering/gravatar_image_tag"
  SUMMARY  = "A configurable and documented Rails view helper for adding gravatars into your Rails application."

  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.author       = AUTHOR
    s.email        = EMAIL
    s.files        = %w(install.rb install.txt MIT-LICENSE README.textile Rakefile) + Dir.glob("{rails,lib,spec}/**/*")
    s.homepage     = HOMEPAGE
    s.name         = GEM
    s.require_path = 'lib'
    s.summary      = SUMMARY
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: gem install jeweler"
end

desc 'Default: spec tests.'
task :default => :spec

desc 'Test the gravatar_image_tag gem.'
RSpec::Core::RakeTask.new do |t|
end

desc "Run all examples with RCov"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', '/opt,spec,Library']
end
