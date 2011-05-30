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

namespace :code do
  desc "Fix line endings of all source files"
  task :fix_line_endings do
    Dir.chdir(File.join(File.dirname(__FILE__), "../..")) do
      files = Dir['**/**{.rb,.html.erb,.rhtml,.rjs,.rsb,.plain.erb,.rxml,.yml,.rake,.eml}']
      files.reject!{ |f|
        f.include?("vendor") ||
        f.include?("lib/SVG") ||
        f.include?("lib/faster_csv") ||
        f.include?("lib/redcloth") ||
        f.include?("lib/diff")
      }

      # handle files in chunks of 50 to avoid too long command lines
      while (slice = files.slice!(0, 50)).present?
        system('ruby', '-i', '-pe', 'gsub(/\s+$/,"\n")', *slice)
      end
    end
  end
end
