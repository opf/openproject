#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# require 'source_annotation_extractor'

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
      elsif item =~ /\.(builder|(r(?:b|xml|js)))\z/
        results.update(extract_annotations_from(item, /\s*(#{tag})\(?\s*(.*)\z/))
      elsif item =~ /\.(rhtml|erb)\z/
        results.update(extract_annotations_from(item, /<%=\s*\s*(#{tag})\(?\s*(.*?)\s*%>/))
      end
    end

    results
  end
end

namespace :redmine do
  namespace :plugins do
    desc 'Enumerate all Redmine plugin hooks and their context parameters'
    task :hook_list do
      PluginSourceAnnotationExtractor.enumerate 'call_hook'
    end

    namespace :test do
      desc 'Runs the plugins unit tests.'
      Rake::TestTask.new units: 'db:test:prepare' do |t|
        t.libs << 'test'
        t.verbose = true
        t.test_files = FileList["plugins/#{ENV['NAME'] || '*'}/test/unit/**/*_test.rb"]
      end

      desc 'Runs the plugins functional tests.'
      Rake::TestTask.new functionals: 'db:test:prepare' do |t|
        t.libs << 'test'
        t.verbose = true
        t.test_files = FileList["plugins/#{ENV['NAME'] || '*'}/test/functional/**/*_test.rb"]
      end

      desc 'Runs the plugins integration tests.'
      Rake::TestTask.new integration: 'db:test:prepare' do |t|
        t.libs << 'test'
        t.verbose = true
        t.test_files = FileList["plugins/#{ENV['NAME'] || '*'}/test/integration/**/*_test.rb"]
      end
    end
  end
end
