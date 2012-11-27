#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

#require 'source_annotation_extractor'

# Modified version of the SourceAnnotationExtractor in railties
# Will search for runable code that uses <tt>call_hook</tt>
class PluginSourceAnnotationExtractor < SourceAnnotationExtractor
  # Returns a hash that maps filenames under +dir+ (recursively) to arrays
  # with their annotations. Only files with annotations are included, and only
  # those with extension +.builder+, +.rb+, +.rxml+, +.rjs+, +.rhtml+, and +.erb+
  # are taken into account.
  def find_in(dir)
    results = {}

    Dir.glob("#{dir}/*") do |item|
      next if File.basename(item)[0] == ?.

      if File.directory?(item)
        results.update(find_in(item))
      elsif item =~ /(hook|test)\.rb/
        # skip
      elsif item =~ /\.(builder|(r(?:b|xml|js)))$/
        results.update(extract_annotations_from(item, /\s*(#{tag})\(?\s*(.*)$/))
      elsif item =~ /\.(rhtml|erb)$/
        results.update(extract_annotations_from(item, /<%=\s*\s*(#{tag})\(?\s*(.*?)\s*%>/))
      end
    end

    results
  end
end

namespace :redmine do
  namespace :plugins do
    desc "Enumerate all Redmine plugin hooks and their context parameters"
    task :hook_list do
      PluginSourceAnnotationExtractor.enumerate 'call_hook'
    end

    desc 'Migrates installed plugins.'
    task :migrate => :environment do
      name = ENV['NAME']
      version = nil
      version_string = ENV['VERSION']
      if version_string
        if version_string =~ /^\d+$/
          version = version_string.to_i
          if name.nil?
            abort "The VERSION argument requires a plugin NAME."
          end
        else
          abort "Invalid VERSION #{version_string} given."
        end
      end

      begin
        Redmine::Plugin.migrate(name, version)
      rescue Redmine::PluginNotFound
        abort "Plugin #{name} was not found."
      end

      Rake::Task["db:schema:dump"].invoke
    end

    desc 'Copies plugins assets into the public directory.'
    task :assets => :environment do
      name = ENV['NAME']

      begin
        Redmine::Plugin.mirror_assets(name)
      rescue Redmine::PluginNotFound
        abort "Plugin #{name} was not found."
      end
    end

    desc 'Runs the plugins tests.'
    task :test do
      Rake::Task["redmine:plugins:test:units"].invoke
      Rake::Task["redmine:plugins:test:functionals"].invoke
      Rake::Task["redmine:plugins:test:integration"].invoke
    end

    namespace :test do
      desc 'Runs the plugins unit tests.'
      Rake::TestTask.new :units => "db:test:prepare" do |t|
        t.libs << "test"
        t.verbose = true
        t.test_files = FileList["plugins/#{ENV['NAME'] || '*'}/test/unit/**/*_test.rb"]
      end

      desc 'Runs the plugins functional tests.'
      Rake::TestTask.new :functionals => "db:test:prepare" do |t|
        t.libs << "test"
        t.verbose = true
        t.test_files = FileList["plugins/#{ENV['NAME'] || '*'}/test/functional/**/*_test.rb"]
      end

      desc 'Runs the plugins integration tests.'
      Rake::TestTask.new :integration => "db:test:prepare" do |t|
        t.libs << "test"
        t.verbose = true
        t.test_files = FileList["plugins/#{ENV['NAME'] || '*'}/test/integration/**/*_test.rb"]
      end
    end
  end
end

namespace :db do
  namespace :migrate do
    task :plugins do
      #noop
    end
  end
end
