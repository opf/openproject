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

module Redmine::MenuManager::MenuController
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    @@menu_items = Hash.new { |hash, key| hash[key] = { default: key, actions: {} } }
    mattr_accessor :menu_items

    # Set the menu item name for a controller or specific actions
    # Examples:
    #   * menu_item :tickets # => sets the menu name to :tickets for the whole controller
    #   * menu_item :tickets, :only => :list # => sets the menu name to :tickets for the 'list' action only
    #   * menu_item :tickets, :only => [:list, :show] # => sets the menu name to :tickets for 2 actions only
    #
    # The default menu item name for a controller is controller_name by default
    # Eg. the default menu item name for ProjectsController is :projects
    def menu_item(id, options = {})
      if actions = options[:only]
        actions = [] << actions unless actions.is_a?(Array)
        actions.each { |a| menu_items[controller_name.to_sym][:actions][a.to_sym] = id }
      else
        menu_items[controller_name.to_sym][:default] = id
      end
    end

    def current_menu_item(actions = :default, &block)
      raise ArgumentError '#current_menu_item requires a block' unless block_given?

      if actions == :default
        menu_items[controller_name.to_sym][:default] = block
      else
        actions = [] << actions unless actions.is_a?(Array)
        actions.each { |a| menu_items[controller_name.to_sym][:actions][a.to_sym] = block }
      end
    end
  end

  def menu_items
    self.class.menu_items
  end

  # Returns the menu item name according to the current action
  def current_menu_item
    return @current_menu_item if @current_menu_item_determined

    @current_menu_item = menu_items[controller_name.to_sym][:actions][action_name.to_sym] ||
                         menu_items[controller_name.to_sym][:default]

    @current_menu_item = if @current_menu_item.is_a?(Symbol)
                           @current_menu_item
                         elsif @current_menu_item.is_a?(Proc)
                           @current_menu_item.call(self)
                         else
                           raise ArgumentError 'Invalid'
                         end

    @current_menu_item_determined = true

    @current_menu_item
  end

  # Redirects user to the menu item of the given project
  # Returns false if user is not authorized
  def redirect_to_project_menu_item(project, name)
    item = Redmine::MenuManager.items(:project_menu).detect { |i| i.name.to_s == name.to_s }
    if item && User.current.allowed_to?(item.url, project) && (item.condition.nil? || item.condition.call(project))
      redirect_to({ item.param => project }.merge(item.url))
      return true
    end
    false
  end
end
