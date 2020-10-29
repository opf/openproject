#!/usr/bin/env ruby
#
# example_basic.rb:: Basic usage of the tree library.
#
# Author:  Anupam Sengupta
# Time-stamp: <2015-12-31 22:17:30 anupam>
# Copyright (C) 2013, 2015 Anupam Sengupta <anupamsg@gmail.com>
#
# The following example implements this tree structure:
#
#                    +------------+
#                    |    ROOT    |
#                    +-----+------+
#            +-------------+------------+
#            |                          |
#    +-------+-------+          +-------+-------+
#    |  CHILD 1      |          |  CHILD 2      |
#    +-------+-------+          +---------------+
#            |
#            |
#    +-------+-------+
#    | GRANDCHILD 1  |
#    +---------------+

# ..... Example starts.
require 'tree'                 # Load the library

# ..... Create the root node first.  Note that every node has a name and an optional content payload.
root_node = Tree::TreeNode.new('ROOT', 'Root Content')
root_node.print_tree

# ..... Now insert the child nodes.  Note that you can "chain" the child insertions for a given path to any depth.
root_node << Tree::TreeNode.new('CHILD1', 'Child1 Content') << Tree::TreeNode.new('GRANDCHILD1', 'GrandChild1 Content')
root_node << Tree::TreeNode.new('CHILD2', 'Child2 Content')

# ..... Lets print the representation to stdout.  This is primarily used for debugging purposes.
root_node.print_tree

# ..... Lets directly access children and grandchildren of the root.  The can be "chained" for a given path to any depth.
child1       = root_node['CHILD1']
grand_child1 = root_node['CHILD1']['GRANDCHILD1']

# ..... Now lets retrieve siblings of the current node as an array.
siblings_of_child1 = child1.siblings

# ..... Lets retrieve immediate children of the root node as an array.
children_of_root = root_node.children

# ..... Retrieve the parent of a node.
parent = child1.parent

# ..... This is a depth-first and L-to-R pre-ordered traversal.
root_node.each { |node| node.content.reverse }

# ..... Lets remove a child node from the root node.
root_node.remove!(child1)
