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
      target_root.prepend(Redmine::MenuManager::MenuItem.new(name, url, options))
    elsif before = options.delete(:before)

      if exists?(before)
        target_root.add_at(Redmine::MenuManager::MenuItem.new(name, url, options), position_of(before))
      else
        target_root.add(Redmine::MenuManager::MenuItem.new(name, url, options))
      end

    elsif after = options.delete(:after)

      if exists?(after)
        target_root.add_at(Redmine::MenuManager::MenuItem.new(name, url, options), position_of(after) + 1)
      else
        target_root.add(Redmine::MenuManager::MenuItem.new(name, url, options))
      end

    elsif options[:last] # don't delete, needs to be stored
      target_root.add_last(Redmine::MenuManager::MenuItem.new(name, url, options))
    else
      target_root.add(Redmine::MenuManager::MenuItem.new(name, url, options))
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
