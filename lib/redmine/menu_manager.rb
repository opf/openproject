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

module Redmine::MenuManager
  def self.map(menu_name)
    @items ||= {}
    mapper = Mapper.new(menu_name.to_sym, @items)
    if block_given?
      yield mapper
    else
      mapper
    end
  end
  
  def self.items(menu_name)
    @items[menu_name.to_sym] || Tree::TreeNode.new(:root, {})
  end
end
