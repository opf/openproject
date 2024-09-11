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

class Redmine::MenuManager::Mapper
  def initialize(menu, items)
    items[menu] ||= Redmine::MenuManager::TreeNode.new(:root, {})
    @menu = menu
    @menu_items = items[menu]
  end

  # Adds an item at the end of the menu. Available options:
  # * param: the parameter name that is used for the project id (default is :project_id)
  # * if: a Proc that is called before rendering the item, the item is displayed only if it returns true
  # * caption that can be:
  #   * a localized string Symbol
  #   * a String
  #   * a Proc that can take the project as argument
  # * before, after: specify where the menu item should be inserted (eg. after: :activity)
  # * parent: menu item will be added as a child of another named menu (eg. parent: :issues)
  # * children: a Proc that is called before rendering the item. The Proc should return an array of MenuItems, which will be added as children to this item.
  #   eg. children: Proc.new {|project| [Redmine::MenuManager::MenuItem.new(...)] }
  # * last: menu item will stay at the end (eg. last: true)
  # * first: menu item will stay at the top (eg. first: true)
  # * html_options: a hash of html options that are passed to link_to
  # * partial: A partial that shall be rendered at that position
  def push(name, url, options = {})
    options = options.dup

    if options[:parent]
      subtree = find(options[:parent])
      target_root = subtree || @menu_items.root

    else
      target_root = @menu_items.root
    end

    # menu item position
    if options.delete(:first)
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
    if found = find(name)
      @menu_items.remove!(found)
    end
  end

  def add_condition(name, condition)
    if found = find(name)
      found.add_condition(condition)
    end
  end

  # Checks if a menu item exists
  def exists?(name)
    @menu_items.any? { |node| node.name == name }
  end

  def find(name)
    @menu_items.find { |node| node.name == name }
  end

  def position_of(name)
    @menu_items.each do |node|
      if node.name == name
        return node.position
      end
    end
  end
end
