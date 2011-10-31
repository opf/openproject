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

namespace :code do
  desc "Fix line endings of all source files"
  task :fix_line_endings do
    Dir.chdir(File.join(File.dirname(__FILE__), "../..")) do
      files = Dir['**/**{.rb,.html.erb,.rhtml,.rjs,.rsb,.plain.erb,.rxml,.yml,.rake,.eml}']
      files.reject!{ |f|
        f.include?("vendor") ||
        f.include?("lib/SVG") ||
        f.include?("lib/redcloth") ||
        f.include?("lib/diff")
      }

      # handle files in chunks of 50 to avoid too long command lines
      while (slice = files.slice!(0, 50)).present?
        system('ruby', '-i', '-pe', 'gsub(/\s+$/,"\n")', *slice)
      end
    end
  end

  desc "Set the magic encoding comment everywhere to UTF-8"
  task :source_encoding do
    shebang = '\s*#!.*?(\n|\r\n)'
    magic_regex = /\A(#{shebang})?\s*(#\W*(en)?coding:.*?$)/mi

    magic_comment = '#-- encoding: UTF-8'

    (Dir['script/**/**'] + Dir['**/**{.rb,.rake}']).each do |file_name|
      next unless File.file?(file_name)

      # We don't skip code here, as we need ALL code files to have UTF-8
      # source encoding
      file_content = File.read(file_name)
      if file_content =~ magic_regex
        file_content.gsub!(magic_regex, "\\1#{magic_comment}")
      else
        if file_content.start_with?("#!")
          # We have a shebang. Encoding comment is to put on the second line
          file_content.sub!(/(\n|\r\n)/, "\\1#{magic_comment}\\1")
        else
          file_content = magic_comment + "\n" + file_content
        end
      end

      File.open(file_name, "w") do |file|
        file.write file_content
      end
    end
  end
end
