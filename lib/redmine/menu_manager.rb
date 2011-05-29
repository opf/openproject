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

module Redmine::MenuManager
  def self.map(menu_name)
    @items ||= {}
    mapper = Mapper.new(menu_name.to_sym, @items)
    if block_given?
      yield mapper
    else
      mapper
    end
  end
  
  def self.items(menu_name)
    @items[menu_name.to_sym] || Redmine::MenuManager::TreeNode.new(:root, {})
  end
end
