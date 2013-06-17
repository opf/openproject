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

module Redmine::MenuManager
  class Menu < TreeNode

    def find_item(name)
      find { |item| item.name == name }
    end

    def place(new_node, position = {})
      target_root = find_target_root(position[:parent])

      # menu item position
      if position.delete(:first)
        target_root.prepend(new_node)
      elsif before = position.delete(:before)

        if find_item(before)
          target_root.add_at(new_node, position_of(before))
        else
          target_root.add(new_node)

        end
      elsif after = position.delete(:after)

        if find_item(after)
          target_root.add_at(new_node, position_of(after) + 1)
        else
          target_root.add(new_node)
        end

      elsif position[:last] # don't delete, needs to be stored
        target_root.add_last(new_node)
      else
        target_root.add(new_node)
      end
    end

    private

    def position_of(name)
      each do |node|
        if node.name == name
          return node.position
        end
      end
    end

    def find_target_root(parent_name)
      if parent_name
        subtree = self.find_item(parent_name)

        if subtree
          target_root = subtree
        else
          target_root = self
        end

      else
        target_root = self
      end
    end
  end
end
