<!--
  README.md

  Copyright (C) 2006-2017 Anupam Sengupta (anupamsg@gmail.com)

-->
# **RubyTree** #

[![Gem Version](https://badge.fury.io/rb/rubytree.png)](http://badge.fury.io/rb/rubytree)
[![Travis Build Status](https://secure.travis-ci.org/evolve75/RubyTree.png)](http://travis-ci.org/evolve75/rubytree)
[![Dependency Status](https://gemnasium.com/evolve75/RubyTree.png)](https://gemnasium.com/evolve75/RubyTree)
[![Code Climate](https://codeclimate.com/github/evolve75/RubyTree.png)](https://codeclimate.com/github/evolve75/RubyTree)
[![Coverage Status](https://coveralls.io/repos/evolve75/RubyTree/badge.png)](https://coveralls.io/r/evolve75/RubyTree)

## DESCRIPTION: ##

**RubyTree** is a pure Ruby implementation of the generic
[tree data structure][tree_data_structure]. It provides a node-based model to
store named nodes in the tree, and provides simple APIs to access, modify and
traverse the structure.

The implementation is *node-centric*, where individual nodes in the tree are the
primary structural elements. All common tree-traversal methods ([pre-order][],
[post-order][], and [breadth-first][]) are supported.

The library mixes in the [Enumerable][] and [Comparable][] modules to allow
access to the tree as a standard collection (iteration, comparison, etc.).

A [Binary tree][] is also provided, which provides the [in-order][] traversal in
addition to the other methods.

**RubyTree** supports importing from, and exporting to [JSON][], and also
supports the Ruby's standard object [marshaling][].

This is a [BSD licensed][BSD] open source project, and is hosted at
[github.com/evolve75/RubyTree][rt@github], and is available as a standard gem
from [rubygems.org/gems/rubytree][rt_gem].

The home page for **RubyTree** is at [rubytree.anupamsg.me][rt_site].

## WHAT'S NEW: ##

See [History](./History.rdoc) for the detailed Changelog.

See [API-CHANGES](./API-CHANGES.rdoc) for the detailed description of
API level changes.

## GETTING STARTED: ##

This is a basic usage example of the library to create and manipulate a tree.
See the [API][rt_doc] documentation for more details.

```ruby
#!/usr/bin/env ruby
#
# example_basic.rb:: Basic usage of the tree library.
#
# Author:  Anupam Sengupta
# Time-stamp: <2013-12-28 12:14:20 anupam>
# Copyright (C) 2013 Anupam Sengupta <anupamsg@gmail.com>
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

# ..... Create the root node first.
# ..... Note that every node has a name and an optional content payload.
root_node = Tree::TreeNode.new("ROOT", "Root Content")
root_node.print_tree

# ..... Now insert the child nodes.
#       Note that you can "chain" the child insertions to any depth.
root_node << Tree::TreeNode.new("CHILD1", "Child1 Content") << Tree::TreeNode.new("GRANDCHILD1", "GrandChild1 Content")
root_node << Tree::TreeNode.new("CHILD2", "Child2 Content")

# ..... Lets print the representation to stdout.
# ..... This is primarily used for debugging purposes.
root_node.print_tree

# ..... Lets directly access children and grandchildren of the root.
# ..... The can be "chained" for a given path to any depth.
child1       = root_node["CHILD1"]
grand_child1 = root_node["CHILD1"]["GRANDCHILD1"]

# ..... Now retrieve siblings of the current node as an array.
siblings_of_child1 = child1.siblings

# ..... Retrieve immediate children of the root node as an array.
children_of_root = root_node.children

# ..... Retrieve the parent of a node.
parent = child1.parent

# ..... This is a depth-first and L-to-R pre-ordered traversal.
root_node.each { |node| node.content.reverse }

# ..... Remove a child node from the root node.
root_node.remove!(child1)

# .... Many more methods are available. Check out the documentation!
```

This example can also be found at
[examples/example_basic.rb](examples/example_basic.rb).

## REQUIREMENTS: ##

* [Ruby][] 2.2.x, 2.3.x or 2.4.x


* Run-time Dependencies:
    * [structured_warnings][]
    * [JSON][] for converting to/from the JSON format


* Development dependencies (not required for installing the gem):
    * [Bundler][] for creating the stable build environment
    * [Rake][] for building the package
    * [Yard][] for the documentation
    * [RSpec][] for additional Ruby Spec test files

## INSTALL: ##

To install the [gem][rt_gem], run this command from a terminal/shell:

    $ gem install rubytree

This should install the gem file for **RubyTree**. Note that you might need to
have super-user privileges (root/sudo) to successfully install the gem.

## DOCUMENTATION: ##

The primary class **RubyTree** is {Tree::TreeNode}. See the class
documentation for an example of using the library.

If the *ri* documentation was generated during install, you can use this
command at the terminal to view the text mode ri documentation:

    $ ri Tree::TreeNode

Documentation for the latest released version is available at:

[rubytree.anupamsg.me/rdoc][rt_doc]

Documentation for the latest git HEAD is available at:

[rdoc.info/projects/evolve75/RubyTree][rt_doc@head]

Note that the documentation is formatted using [Yard][].

## DEVELOPERS: ##

This section is only for modifying **RubyTree** itself. It is not required for
using the library!

You can download the latest released source code as a tar or zip file, as
mentioned above in the installation section.

Alternatively, you can checkout the latest commit/revision from the Version
Control System. Note that **RubyTree**'s primary [SCM][] is [git][] and is
hosted on [github.com][rt@github].

### Using the git Repository ###

The git repository is available at [github.com/evolve75/RubyTree][rt@github].

For cloning the git repository, use one of the following commands:

    $ git clone git://github.com/evolve75/RubyTree.git

or

    $ git clone http://github.com/evolve75/RubyTree.git

### Setting up the Development Environment ###

**RubyTree** uses [Bundler][] to manage its dependencies. This allows for a
simplified dependency management, for both run-time as well as during build.

After checking out the source, run:

    $ gem install bundler
    $ bundle install
    $ rake test
    $ rake doc:yard
    $ rake gem:package

These steps will install any missing dependencies, run the tests/specs,
generate the documentation, and finally generate the gem file.

Note that the documentation uses [Yard][], which will be
downloaded and installed automatically by [Bundler][].

## ACKNOWLEDGMENTS: ##

A big thanks to the following contributors for helping improve **RubyTree**:

1. [Dirk Breuer](http://github.com/railsbros-dirk) for contributing the JSON
   conversion code.
2. Vincenzo Farruggia for contributing the (sub)tree cloning code.
3. [Eric Cline](https://github.com/escline) for the Rails JSON encoding fix.
4. [Darren Oakley](https://github.com/dazoakley) for the tree merge methods.
5. [Youssef Rebahi-Gilbert](https://github.com/ysf) for the code to check
   duplicate node names in the tree (globally unique names).
6. [Paul de Courcel](https://github.com/pdecourcel) for adding the
   `postordered_each` method.
7. [Jen Hamon](http://www.github.com/jhamon) for adding the `from_hash` method.
8. [Evan Sharp](https://github.com/packetmonkey) for adding the `rename` and
   `rename_child` methods.
9. [Aidan Steele](https://github.com/aidansteele) for performance improvements
   to `is_root?` and `node_depth`.
10. [Marco Ziccadi](https://github.com/MZic) for adding the `path_as_string` and
    `path_as_array` methods.

## LICENSE: ##

**RubyTree** is licensed under the terms of the [BSD][] license. See
[LICENSE.md](./LICENSE.md) for details.

{include:file:LICENSE.md}

        __       _           _
       /__\_   _| |__  _   _| |_ _ __ ___  ___
      / \// | | | '_ \| | | | __| '__/ _ \/ _ \
     / _  \ |_| | |_) | |_| | |_| | |  __/  __/
     \/ \_/\__,_|_.__/ \__, |\__|_|  \___|\___|
                      |___/

[BSD]:                  http://opensource.org/licenses/bsd-license.php "BSD License"
[Binary tree]:          http://en.wikipedia.org/wiki/Binary_tree "Binary Tree Data Structure"
[Bundler]:              http://bundler.io "Bundler"
[Comparable]:           http://ruby-doc.org/core-2.4.2/Comparable.html "Comparable mix-in"
[Enumerable]:           http://ruby-doc.org/core-2.4.2/Enumerable.html "Enumerable mix-in"
[JSON]:                 http://flori.github.com/json "JSON"
[Rake]:                 https://rubygems.org/gems/rake "Rake"
[Ruby]:                 http://www.ruby-lang.org "Ruby Programming Language"
[SCM]:                  http://en.wikipedia.org/wiki/Source_Code_Management "Source Code Management"
[Yard]:                 http://yardoc.org "Yard Document Generator"
[breadth-first]:        http://en.wikipedia.org/wiki/Breadth-first_search "Breadth-first (level-first) Traversal"
[git]:                  http://git-scm.com "Git SCM"
[in-order]:             http://en.wikipedia.org/wiki/Tree_traversal#In-order "In-order (symmetric) Traversal"
[marshaling]:           http://ruby-doc.org/core-2.4.2/Marshal.html "Marshaling in Ruby"
[post-order]:           http://en.wikipedia.org/wiki/Tree_traversal#Post-order "Post-ordered Traversal"
[pre-order]:            http://en.wikipedia.org/wiki/Tree_traversal#Pre-order "Pre-ordered Traversal"
[rt@github]:            http://github.com/evolve75/RubyTree "RubyTree Project Page on Github"
[rt_doc@head]:          http://rdoc.info/projects/evolve75/RubyTree "RubyTree Documentation for VCS Head"
[rt_doc]:               http://rubytree.anupamsg.me/rdoc "RubyTree Documentation"
[rt_gem]:               http://rubygems.org/gems/rubytree "RubyTree Gem"
[rt_site]:              http://rubytree.anupamsg.me "RubyTree Site"
[structured_warnings]:  http://github.com/schmidt/structured_warnings "structured_warnings"
[tree_data_structure]:  http://en.wikipedia.org/wiki/Tree_data_structure "Tree Data Structure"
[RSpec]:                https://relishapp.com/rspec/

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/evolve75/rubytree/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
