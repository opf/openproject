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

require 'tree' # gem install rubytree

# Monkey patch the TreeNode to add on a few more methods :nodoc:
module TreeNodePatch
  def self.included(base)
    base.class_eval do
      attr_reader :last_items_count
      
      def initialize_with_redmine(name, content = nil)
        extend InstanceMethods
        @last_items_count = 0

        initialize_without_redmine(name, content)
      end
      alias_method_chain :initialize, :redmine
    end
  end
  
  module InstanceMethods
    # Adds the specified child node to the receiver node.  The child node's
    # parent is set to be the receiver.  The child is added as the first child in
    # the current list of children for the receiver node.
    def prepend(child)
      raise "Child already added" if @childrenHash.has_key?(child.name)

      @childrenHash[child.name]  = child
      @children = [child] + @children
      child.parent = self
      return child

    end

    # Adds the specified child node to the receiver node.  The child node's
    # parent is set to be the receiver.  The child is added at the position
    # into the current list of children for the receiver node.
    def add_at(child, position)
      raise "Child already added" if @childrenHash.has_key?(child.name)

      @childrenHash[child.name]  = child
      @children = @children.insert(position, child)
      child.parent = self
      return child

    end

    def add_last(child)
      raise "Child already added" if @childrenHash.has_key?(child.name)

      @childrenHash[child.name]  = child
      @children <<  child
      @last_items_count += 1
      child.parent = self
      return child

    end

    # Adds the specified child node to the receiver node.  The child node's
    # parent is set to be the receiver.  The child is added as the last child in
    # the current list of children for the receiver node.
    def add(child)
      raise "Child already added" if @childrenHash.has_key?(child.name)

      @childrenHash[child.name]  = child
      position = @children.size - @last_items_count
      @children.insert(position, child)
      child.parent = self
      return child

    end

    # Wrapp remove! making sure to decrement the last_items counter if
    # the removed child was a last item
    def remove!(child)
      @last_items_count -= +1 if child && child.last
      super
    end


    # Will return the position (zero-based) of the current child in
    # it's parent
    def position
      self.parent.children.index(self)
    end
  end
end
unless Tree::TreeNode.included_modules.include?(TreeNodePatch)
  Tree::TreeNode.send(:include, TreeNodePatch)
end

module Redmine
  module MenuManager
    class MenuError < StandardError #:nodoc:
    end
    
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
        @current_menu_item ||= menu_items[controller_name.to_sym][:actions][action_name.to_sym] ||
                                 menu_items[controller_name.to_sym][:default]
      end
      
      # Redirects user to the menu item of the given project
      # Returns false if user is not authorized
      def redirect_to_project_menu_item(project, name)
        item = Redmine::MenuManager.items(:project_menu).detect {|i| i.name.to_s == name.to_s}
        if item && User.current.allowed_to?(item.url, project) && (item.condition.nil? || item.condition.call(project))
          redirect_to({item.param => project}.merge(item.url))
          return true
        end
        false
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
      
      def display_main_menu?(project)
        menu_name = project && !project.new_record? ? :project_menu : :application_menu
        Redmine::MenuManager.items(menu_name).size > 1 # 1 element is the root
      end

      def render_menu(menu, project=nil)
        links = []
        menu_items_for(menu, project) do |node|
          links << render_menu_node(node, project)
        end
        links.empty? ? nil : content_tag('ul', links.join("\n"))
      end

      def render_menu_node(node, project=nil)
        if node.hasChildren? || !node.child_menus.nil?
          return render_menu_node_with_children(node, project)
        else
          caption, url, selected = extract_node_details(node, project)
          return content_tag('li',
                               render_single_menu_node(node, caption, url, selected))
        end
      end

      def render_menu_node_with_children(node, project=nil)
        caption, url, selected = extract_node_details(node, project)

        html = [].tap do |html|
          html << '<li>'
          # Parent
          html << render_single_menu_node(node, caption, url, selected)

          # Standard children
          standard_children_list = "".tap do |child_html|
            node.children.each do |child|
              child_html << render_menu_node(child, project)
            end
          end

          html << content_tag(:ul, standard_children_list, :class => 'menu-children') unless standard_children_list.empty?

          # Unattached children
          unattached_children_list = render_unattached_children_menu(node, project)
          html << content_tag(:ul, unattached_children_list, :class => 'menu-children unattached') unless unattached_children_list.blank?

          html << '</li>'
        end
        return html.join("\n")
      end

      # Returns a list of unattached children menu items
      def render_unattached_children_menu(node, project)
        return nil unless node.child_menus

        "".tap do |child_html|
          unattached_children = node.child_menus.call(project)
          # Tree nodes support #each so we need to do object detection
          if unattached_children.is_a? Array
            unattached_children.each do |child|
              child_html << content_tag(:li, render_unattached_menu_item(child, project)) 
            end
          else
            raise MenuError, ":child_menus must be an array of MenuItems"
          end
        end
      end

      def render_single_menu_node(item, caption, url, selected)
        link_to(h(caption), url, item.html_options(:selected => selected))
      end

      def render_unattached_menu_item(menu_item, project)
        raise MenuError, ":child_menus must be an array of MenuItems" unless menu_item.is_a? MenuItem

        if User.current.allowed_to?(menu_item.url, project)
          link_to(h(menu_item.caption),
                  menu_item.url,
                  menu_item.html_options)
        end
      end
      
      def menu_items_for(menu, project=nil)
        items = []
        Redmine::MenuManager.items(menu).root.children.each do |node|
          if allowed_node?(node, User.current, project)
            if block_given?
              yield node
            else
              items << node  # TODO: not used?
            end
          end
        end
        return block_given? ? nil : items
      end

      def extract_node_details(node, project=nil)
        item = node
        url = case item.url
        when Hash
          project.nil? ? item.url : {item.param => project}.merge(item.url)
        when Symbol
          send(item.url)
        else
          item.url
        end
        caption = item.caption(project)
        return [caption, url, (current_menu_item == item.name)]
      end

      # Checks if a user is allowed to access the menu item by:
      #
      # * Checking the conditions of the item
      # * Checking the url target (project only)
      def allowed_node?(node, user, project)
        if node.condition && !node.condition.call(project)
          # Condition that doesn't pass
          return false
        end

        if project
          return user && user.allowed_to?(node.url, project)
        else
          # outside a project, all menu items allowed
          return true
        end
      end
    end
    
    class << self
      def map(menu_name)
        @items ||= {}
        mapper = Mapper.new(menu_name.to_sym, @items)
        if block_given?
          yield mapper
        else
          mapper
        end
      end
      
      def items(menu_name)
        @items[menu_name.to_sym] || Tree::TreeNode.new(:root, {})
      end
    end
    
    class Mapper
      def initialize(menu, items)
        items[menu] ||= Tree::TreeNode.new(:root, {})
        @menu = menu
        @menu_items = items[menu]
      end
      
      @@last_items_count = Hash.new {|h,k| h[k] = 0}
      
      # Adds an item at the end of the menu. Available options:
      # * param: the parameter name that is used for the project id (default is :id)
      # * if: a Proc that is called before rendering the item, the item is displayed only if it returns true
      # * caption that can be:
      #   * a localized string Symbol
      #   * a String
      #   * a Proc that can take the project as argument
      # * before, after: specify where the menu item should be inserted (eg. :after => :activity)
      # * parent: menu item will be added as a child of another named menu (eg. :parent => :issues)
      # * children: a Proc that is called before rendering the item. The Proc should return an array of MenuItems, which will be added as children to this item.
      #   eg. :children => Proc.new {|project| [Redmine::MenuManager::MenuItem.new(...)] }
      # * last: menu item will stay at the end (eg. :last => true)
      # * html_options: a hash of html options that are passed to link_to
      def push(name, url, options={})
        options = options.dup

        if options[:parent]
          subtree = self.find(options[:parent])
          if subtree
            target_root = subtree
          else
            target_root = @menu_items.root
          end

        else
          target_root = @menu_items.root
        end

        # menu item position
        if first = options.delete(:first)
          target_root.prepend(MenuItem.new(name, url, options))
        elsif before = options.delete(:before)

          if exists?(before)
            target_root.add_at(MenuItem.new(name, url, options), position_of(before))
          else
            target_root.add(MenuItem.new(name, url, options))
          end

        elsif after = options.delete(:after)

          if exists?(after)
            target_root.add_at(MenuItem.new(name, url, options), position_of(after) + 1)
          else
            target_root.add(MenuItem.new(name, url, options))
          end
          
        elsif options[:last] # don't delete, needs to be stored
          target_root.add_last(MenuItem.new(name, url, options))
        else
          target_root.add(MenuItem.new(name, url, options))
        end
      end
      
      # Removes a menu item
      def delete(name)
        if found = self.find(name)
          @menu_items.remove!(found)
        end
      end

      # Checks if a menu item exists
      def exists?(name)
        @menu_items.any? {|node| node.name == name}
      end

      def find(name)
        @menu_items.find {|node| node.name == name}
      end

      def position_of(name)
        @menu_items.each do |node|
          if node.name == name
            return node.position
          end
        end
      end
    end
    
    class MenuItem < Tree::TreeNode
      include Redmine::I18n
      attr_reader :name, :url, :param, :condition, :parent, :child_menus, :last
      
      def initialize(name, url, options)
        raise ArgumentError, "Invalid option :if for menu item '#{name}'" if options[:if] && !options[:if].respond_to?(:call)
        raise ArgumentError, "Invalid option :html for menu item '#{name}'" if options[:html] && !options[:html].is_a?(Hash)
        raise ArgumentError, "Cannot set the :parent to be the same as this item" if options[:parent] == name.to_sym
        raise ArgumentError, "Invalid option :children for menu item '#{name}'" if options[:children] && !options[:children].respond_to?(:call)
        @name = name
        @url = url
        @condition = options[:if]
        @param = options[:param] || :id
        @caption = options[:caption]
        @html_options = options[:html] || {}
        # Adds a unique class to each menu item based on its name
        @html_options[:class] = [@html_options[:class], @name.to_s.dasherize].compact.join(' ')
        @parent = options[:parent]
        @child_menus = options[:children]
        @last = options[:last] || false
        super @name.to_sym
      end
      
      def caption(project=nil)
        if @caption.is_a?(Proc)
          c = @caption.call(project).to_s
          c = @name.to_s.humanize if c.blank?
          c
        else
          if @caption.nil?
            l_or_humanize(name, :prefix => 'label_')
          else
            @caption.is_a?(Symbol) ? l(@caption) : @caption
          end
        end
      end
      
      def html_options(options={})
        if options[:selected]
          o = @html_options.dup
          o[:class] += ' selected'
          o
        else
          @html_options
        end
      end
    end    
  end
end
