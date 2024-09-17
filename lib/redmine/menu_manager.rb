#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module Redmine::MenuManager
  def self.map(menu_name, &menu_builder)
    @menu_builder_queues ||= {}
    current_queue = @menu_builder_queues[menu_name.to_sym] ||= []
    current_queue.push menu_builder
  end

  def self.loose(menu_name, &menu_builder)
    @temp_menu_builder_queues ||= {}
    current_queue = @temp_menu_builder_queues[menu_name.to_sym] ||= []
    current_queue.push menu_builder
  end

  def self.items(menu_name, project = nil)
    items = {}

    mapper = Mapper.new(menu_name.to_sym, items)
    potential_items = @menu_builder_queues[menu_name.to_sym]
    potential_items += @temp_menu_builder_queues[menu_name.to_sym] if @temp_menu_builder_queues and @temp_menu_builder_queues[menu_name.to_sym]

    @temp_menu_builder_queues = {}

    potential_items.each do |menu_builder|
      menu_builder.call(mapper, project)
    end

    items[menu_name.to_sym] || Redmine::MenuManager::TreeNode.new(:root, {})
  end
end
