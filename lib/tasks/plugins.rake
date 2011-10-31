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

require 'source_annotation_extractor'

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
  end
end
