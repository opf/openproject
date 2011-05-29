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
    unless `which fromdos`.present?
      raise "fromdos command not found"
    end
    
    Dir['**/**{.rb,.html.erb,.rhtml,.rjs,.rsb,.plain.erb,.rxml,.yml,.rake,.eml}'].each do |file_name|
      next if file_name.include?("vendor")
      system("fromdos #{file_name}")
    end
    
  end
end
