# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

module Redmine
  module MenuManager
    module MenuController
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        @@menu_items = Hash.new {|hash, key| hash[key] = {:default => key, :actions => {}}}
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
            actions.each {|a| menu_items[controller_name.to_sym][:actions][a.to_sym] = id}
          else
            menu_items[controller_name.to_sym][:default] = id
          end
        end
      end
      
      def menu_items
        self.class.menu_items
      end
      
      # Returns the menu item name according to the current action
      def current_menu_item
        menu_items[controller_name.to_sym][:actions][action_name.to_sym] ||
          menu_items[controller_name.to_sym][:default]
      end
    end
    
    module MenuHelper
      # Returns the current menu item name
      def current_menu_item
        @controller.current_menu_item
      end
      
      # Renders the application main menu as a ul element
      def render_main_menu(project)
        links = []
        Redmine::MenuManager.allowed_items(:project_menu, User.current, project).each do |item|
          unless item.condition && !item.condition.call(project)
            links << content_tag('li', 
                       link_to(l(item.caption), {item.param => project}.merge(item.url),
                               (current_menu_item == item.name ? item.html_options.merge(:class => 'selected') : item.html_options)))
          end
        end if project && !project.new_record?
        links.empty? ? nil : content_tag('ul', links.join("\n"))
      end
    end
    
    class << self
      def map(menu_name)
        mapper = Mapper.new
        yield mapper
        @items ||= {}
        @items[menu_name.to_sym] ||= []
        @items[menu_name.to_sym] += mapper.items
      end
      
      def items(menu_name)
        @items[menu_name.to_sym] || []
      end
      
      def allowed_items(menu_name, user, project)
        items(menu_name).select {|item| user && user.allowed_to?(item.url, project)}
      end
    end
    
    class Mapper
      # Adds an item at the end of the menu. Available options:
      # * param: the parameter name that is used for the project id (default is :id)
      # * condition: a proc that is called before rendering the item, the item is displayed only if it returns true
      # * caption: the localized string key that is used as the item label
      # * html_options: a hash of html options that are passed to link_to
      def push(name, url, options={})
        @items ||= []
        @items << MenuItem.new(name, url, options)
      end
      
      def items
        @items
      end
    end
    
    class MenuItem
      attr_reader :name, :url, :param, :condition, :caption, :html_options
      
      def initialize(name, url, options)
        @name = name
        @url = url
        @condition = options[:if]
        @param = options[:param] || :id
        @caption = options[:caption] || name.to_s.humanize
        @html_options = options[:html] || {}
      end
    end    
  end
end
