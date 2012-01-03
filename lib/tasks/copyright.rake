#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

namespace :copyright do
  desc "Update the copyright on the source files"
  task :update do
    short_copyright = File.readlines("doc/COPYRIGHT_short.rdoc").collect do |line|
      "# #{line}".rstrip
    end.join("\n")

    short_copyright_as_rdoc = "#-- copyright\n" + short_copyright + "\n#++"

    Dir['**/**{.rb,.rake}'].each do |file_name|
      # Skip 3rd party code
      next if file_name.include?("vendor") ||
        file_name.include?("lib/SVG") ||
        file_name.include?("lib/redcloth") ||
        file_name.include?("lib/diff")

      file_content = File.read(file_name)
      @copyright_regex = /^#--\s*copyright.*?\+\+/m
      if file_content.match(@copyright_regex)
        file_content.gsub!(@copyright_regex, short_copyright_as_rdoc)
      else
        file_content = short_copyright_as_rdoc + "\n\n" + file_content # Prepend
      end

      File.open(file_name, "w") do |file|
        file.write file_content
      end

    end

  end
end
