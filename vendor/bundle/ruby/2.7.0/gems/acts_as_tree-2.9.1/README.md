# ActsAsTree
[![Build Status](https://secure.travis-ci.org/amerine/acts_as_tree.svg?branch=master)](http://travis-ci.org/amerine/acts\_as\_tree)
[![Gem Version](https://badge.fury.io/rb/acts_as_tree.svg)](http://badge.fury.io/rb/acts\_as\_tree)

ActsAsTree extends ActiveRecord to add simple support for organizing items into parent–children relationships. By default, ActsAsTree expects a foreign key column called `parent_id`.

## Example

```ruby
class Category < ActiveRecord::Base
  acts_as_tree order: "name"
end

root      = Category.create("name" => "root")
child1    = root.children.create("name" => "child1")
subchild1 = child1.children.create("name" => "subchild1")

root.parent   # => nil
child1.parent # => root
root.children # => [child1]
root.children.first.children.first # => subchild1
```

We also have a convenient `TreeView` module you can mixin if you want a little visual representation of the tree strucuture. Example:

```ruby
class Category < ActiveRecord::Base
  extend ActsAsTree::TreeView

  acts_as_tree order: 'name'
end

> Category.tree_view(:name)
root
 |_ child1
 |    |_ subchild1
 |    |_ subchild2
 |_ child2
      |_ subchild3
      |_ subchild4
=> nil
```

And there's a `TreeWalker` module (traversing the tree using depth-first search (default) or breadth-first search) as well. Example given the Model `Page` as

```ruby
class Page < ActiveRecord::Base
  extend ActsAsTree::TreeWalker

  acts_as_tree order: 'rank'
end
```

In your view you could traverse the tree using

```erb
<% Page.walk_tree do |page, level| %>
  <%= link_to "#{'-'*level}#{page.name}", page_path(page) %><br />
<% end %>
```

You also could use walk\_tree as an instance method such as:

```erb
<% Page.first.walk_tree do |page, level| %>
  <%= link_to "#{'-'*level}#{page.name}", page_path(page) %><br />
<% end %>
```

## Compatibility

We no longer support Ruby 1.8 or versions of Rails/ActiveRecord older than 3.0. If you're using a version of ActiveRecord older than 3.0 please use 0.1.1.

Moving forward we will do our best to support the latest versions of ActiveRecord and Ruby.

## Change Log

The Change Log has moved to the [releases](https://github.com/amerine/acts_as_tree/releases) page.

## Note on Patches/Pull Requests

1. Fork the project.
2. Make your feature addition or bug fix.
3. Add tests for it. This is important so we don't break it in a future version
   unintentionally.
4. Commit, do not mess with rakefile, version, or history. (if you want to have
   your own version, that is fine but bump version in a commit by itself so we can
   ignore when we pull)
5. Send us a pull request. Bonus points for topic branches.
6. All contributors to this project, after their first accepted patch, are given push
   access to the repository and are welcome as full contributors to ActsAsTree. All
   we ask is that all changes go through CI and a Pull Request before merging.

## Releasing new versions

1. We follow Semver. So if you're shipping interface breaking changes then bump
   the major version. We don't care if we ship version 1101.1.1, as long as
   people know that 1101.1.1 has breaking differences from 1100.0. If you're
   adding new features, but not changing existing functionality bump the minor
   version, if you're shipping a bugfix, just bump the patch.
2. Following the above rules, change the version found in lib/acts\_as\_tree/version.rb.
3. Commit these changes in one "release-prep" commit (on the master branch).
4. Push that commit up to the repo.
5. Run `rake release`
   This will create and push a tag to GitHub, then generate a gem and push it to
   Rubygems.
6. Create a new release from the tag on GitHub, by choosing "Draft a new release" button
   on the [releases](https://github.com/amerine/acts_as_tree/releases) tab and include
   the relevant changes in the description.
7. Profit.

## License (MIT)

Copyright (c) 2007 David Heinemeier Hansson

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the 'Software'), to deal in the
Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
