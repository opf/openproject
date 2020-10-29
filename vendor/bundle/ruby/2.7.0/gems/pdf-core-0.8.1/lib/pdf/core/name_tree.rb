# frozen_string_literal: true

require 'pdf/core/utils'

# name_tree.rb : Implements NameTree for PDF
#
# Copyright November 2008, Jamis Buck. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#
module PDF
  module Core
    module NameTree #:nodoc:
      class Node #:nodoc:
        attr_reader :children
        attr_reader :limit
        attr_reader :document
        attr_accessor :parent
        attr_accessor :ref

        def initialize(document, limit, parent = nil)
          @document = document
          @children = []
          @limit = limit
          @parent = parent
          @ref = nil
        end

        def empty?
          children.empty?
        end

        def size
          leaf? ? children.size : children.map(&:size).reduce(:+)
        end

        def leaf?
          children.empty? || children.first.is_a?(Value)
        end

        def add(name, value)
          self << Value.new(name, value)
        end

        def to_hash
          hash = {}

          hash[:Limits] = [least, greatest] if parent
          if leaf?
            hash[:Names] = children if leaf?
          else
            hash[:Kids] = children.map(&:ref)
          end

          hash
        end

        def least
          if leaf?
            children.first.name
          else
            children.first.least
          end
        end

        def greatest
          if leaf?
            children.last.name
          else
            children.last.greatest
          end
        end

        def <<(value)
          if children.empty?
            children << value
          elsif leaf?
            children.insert(insertion_point(value), value)
            split! if children.length > limit
          else
            fit = children.detect { |child| child >= value }
            fit ||= children.last
            fit << value
          end

          value
        end

        def >=(other)
          children.empty? || children.last >= other
        end

        def split!
          if parent
            parent.split(self)
          else
            left = new_node(self)
            right = new_node(self)
            split_children(self, left, right)
            children.replace([left, right])
          end
        end

        # Returns a deep copy of this node, without copying expensive things
        # like the ref to @document.
        #
        def deep_copy
          node = dup
          node.instance_variable_set('@children', Utils.deep_clone(children))
          node.instance_variable_set('@ref',
            node.ref ? node.ref.deep_copy : nil)
          node
        end

        protected

        def split(node)
          new_child = new_node(self)
          split_children(node, node, new_child)
          index = children.index(node)
          children.insert(index + 1, new_child)
          split! if children.length > limit
        end

        private

        def new_node(parent = nil)
          node = Node.new(document, limit, parent)
          node.ref = document.ref!(node)
          node
        end

        def split_children(node, left, right)
          half = (node.limit + 1) / 2

          left_children = node.children[0...half]
          right_children = node.children[half..-1]

          left.children.replace(left_children)
          right.children.replace(right_children)

          unless node.leaf?
            left_children.each { |child| child.parent = left }
            right_children.each { |child| child.parent = right }
          end
        end

        def insertion_point(value)
          children.each_with_index do |child, index|
            return index if child >= value
          end
          children.length
        end
      end

      class Value #:nodoc:
        include Comparable

        attr_reader :name
        attr_reader :value

        def initialize(name, value)
          @name = PDF::Core::LiteralString.new(name)
          @value = value
        end

        def <=>(other)
          name <=> other.name
        end

        def inspect
          "#<Value: #{name.inspect} : #{value.inspect}>"
        end

        def to_s
          "#{name} : #{value}"
        end
      end
    end
  end
end
