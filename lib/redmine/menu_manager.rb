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

require 'gloc'

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
      
      # Renders the application main menu
      def render_main_menu(project)
        render_menu((project && !project.new_record?) ? :project_menu : :application_menu, project)
      end
      
      def render_menu(menu, project=nil)
        links = []
        Redmine::MenuManager.allowed_items(menu, User.current, project).each do |item|
          unless item.condition && !item.condition.call(project)
            url = case item.url
            when Hash
              project.nil? ? item.url : {item.param => project}.merge(item.url)
            when Symbol
              send(item.url)
            else
              item.url
            end
            #url = (project && item.url.is_a?(Hash)) ? {item.param => project}.merge(item.url) : (item.url.is_a?(Symbol) ? send(item.url) : item.url)
            links << content_tag('li', 
              link_to(l(item.caption), url, (current_menu_item == item.name ? item.html_options.merge(:class => 'selected') : item.html_options)))
          end
        end
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
        project ? items(menu_name).select {|item| user && user.allowed_to?(item.url, project)} : items(menu_name)
      end
    end
    
    class Mapper
      # Adds an item at the end of the menu. Available options:
      # * param: the parameter name that is used for the project id (default is :id)
      # * if: a proc that is called before rendering the item, the item is displayed only if it returns true
      # * caption: the localized string key that is used as the item label
      # * html_options: a hash of html options that are passed to link_to
      def push(name, url, options={})
        items << MenuItem.new(name, url, options)
      end
      
      def items
        @items ||= []
      end
    end
    
    class MenuItem
      include GLoc
      attr_reader :name, :url, :param, :condition, :html_options
      
      def initialize(name, url, options)
        raise "Invalid option :if for menu item '#{name}'" if options[:if] && !options[:if].respond_to?(:call)
        raise "Invalid option :html for menu item '#{name}'" if options[:html] && !options[:html].is_a?(Hash)
        @name = name
        @url = url
        @condition = options[:if]
        @param = options[:param] || :id
        @caption_key = options[:caption]
        @html_options = options[:html] || {}
      end
      
      def caption
        # check if localized string exists on first render (after GLoc strings are loaded)
        @caption ||= (@caption_key || (l_has_string?("label_#{@name}".to_sym) ? "label_#{@name}".to_sym : @name.to_s.humanize))
      end
    end    
  end
end
