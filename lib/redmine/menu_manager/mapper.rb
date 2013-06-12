#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Redmine::MenuManager::Mapper
  def initialize(menu, items)
    items[menu] ||= Redmine::MenuManager::TreeNode.new(:root, {})
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
  def push(name, content = nil, options={})
    options = options.dup

    node_granter = granter(content, options)
    node_content = content(content, options)

    new_node = Redmine::MenuManager::MenuItem.new(name, node_content, node_granter)

    add(new_node, options)
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

  private

  def granter(content, options)
    Redmine::MenuManager::Granter::Factory.build(content, options)
  end

  def content(content, options)
    Redmine::MenuManager::Content::Factory.build(content, options)
  end

  def find_target_root(parent_name)
    if parent_name
      subtree = self.find(parent_name)

      if subtree
        target_root = subtree
      else
        target_root = @menu_items.root
      end

    else
      target_root = @menu_items.root
    end
  end

  def add(new_node, options)
    target_root = find_target_root(options[:parent])

    # menu item position
    if first = options.delete(:first)
      target_root.prepend(new_node)
    elsif before = options.delete(:before)

      if exists?(before)
        target_root.add_at(new_node, position_of(before))
      else
        target_root.add(new_node)

      end
    elsif after = options.delete(:after)

      if exists?(after)
        target_root.add_at(new_node, position_of(after) + 1)
      else
        target_root.add(new_node)
      end

    elsif options[:last] # don't delete, needs to be stored
      target_root.add_last(new_node)
    else
      target_root.add(new_node)
    end
  end
end

class Redmine::MenuManager::MapDeferrer
  def initialize(menu_builder_queue)
    @menu_builder_queue = menu_builder_queue
  end

  def defer(method, *args)
    ActiveSupport::Deprecation.warn "Calling #{method.to_s} and accessing the the menu object from outside of the block attached to the map method is deprecated and will be removed in ChiliProject 3.0. Please access the menu object from within the attached block instead. Please also note the differences between the APIs.", caller.drop(1)
    menu_builder = proc{ |menu_mapper| menu_mapper.send(method, *args) }
    @menu_builder_queue.push(menu_builder)
  end

  [:push, :delete, :exists?, :find, :position_of].each do |method|
    define_method method do |*args|
      defer(method, *args)
    end
  end
end
