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

module Redmine::MenuManager
  def self.map(menu_name, &menu_builder)
    @menu_builder_queues ||= {}
    current_queue = @menu_builder_queues[menu_name.to_sym] ||= []

    if menu_builder
      current_queue.push menu_builder
    else
      MapDeferrer.new current_queue
    end
  end

  def self.items(menu_name)
    items = {}

    mapper = Mapper.new(menu_name.to_sym, items)
    @menu_builder_queues[menu_name.to_sym].each do |menu_builder|
      menu_builder.call(mapper)
    end

    items[menu_name.to_sym] || Redmine::MenuManager::TreeNode.new(:root, {})
  end
end
