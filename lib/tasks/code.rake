#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

namespace :code do
  desc 'Fix line endings of all source files'
  task :fix_line_endings do
    Dir.chdir(File.join(File.dirname(__FILE__), '../..')) do
      files = Dir['**/**{.rb,.html.erb,.rhtml,.rjs,.plain.erb,.rxml,.yml,.rake,.eml}']
      files.reject! do |f|
        f.include?('lib/plugins') ||
          f.include?('lib/diff')
      end

      # handle files in chunks of 50 to avoid too long command lines
      while (slice = files.slice!(0, 50)).present?
        system('ruby', '-i', '-pe', 'gsub(/\s+\z/,"\n")', *slice)
      end
    end
  end

  desc 'Set the magic encoding comment everywhere to UTF-8'
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
      elsif file_content.start_with?('#!')
        file_content.sub!(/(\n|\r\n)/, "\\1#{magic_comment}\\1")
      # We have a shebang. Encoding comment is to put on the second line
      else
        file_content = magic_comment + "\n" + file_content
      end

      File.open(file_name, 'w') do |file|
        file.write file_content
      end
    end
  end
end
