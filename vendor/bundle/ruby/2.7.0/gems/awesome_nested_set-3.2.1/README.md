# Awesome Nested Set

[![Build Status](https://travis-ci.org/collectiveidea/awesome_nested_set.svg?branch=master)](https://travis-ci.org/collectiveidea/awesome_nested_set) [![Code Climate](https://codeclimate.com/github/collectiveidea/awesome_nested_set.svg)](https://codeclimate.com/github/collectiveidea/awesome_nested_set) [![Security](https://hakiri.io/github/collectiveidea/awesome_nested_set/master.svg)](https://hakiri.io/github/collectiveidea/awesome_nested_set/master)


Awesome Nested Set is an implementation of the nested set pattern for ActiveRecord models.
It is a replacement for acts_as_nested_set and BetterNestedSet, but more awesome.

Version 3.1 supports Rails 5 & 4. Version 2 supports Rails 3. Gem versions prior to 2.0 support Rails 2.

## What makes this so awesome?

This is a new implementation of nested set based off of BetterNestedSet that fixes some bugs, removes tons of duplication, adds a few useful methods, and adds STI support.


## Installation

Add to your Gemfile:

```ruby
gem 'awesome_nested_set'
```

## Usage

To make use of `awesome_nested_set` your model needs to have 3 fields:
`lft`, `rgt`, and `parent_id`. The names of these fields are configurable.
You can also have optional fields: `depth` and `children_count`. These fields are configurable.
Note that the `children_count` column must have `null: false` and `default: 0` to
function properly.

```ruby
class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.string :name
      t.integer :parent_id, :null => true, :index => true
      t.integer :lft, :null => false, :index => true
      t.integer :rgt, :null => false, :index => true

      # optional fields
      t.integer :depth, :null => false, :default => 0
      t.integer :children_count, :null => false, :default => 0
    end
  end

  def self.down
    drop_table :categories
  end
end
```

Enable the nested set functionality by declaring `acts_as_nested_set` on your model

```ruby
class Category < ActiveRecord::Base
  acts_as_nested_set
end
```

Run `rake rdoc` to generate the API docs and see [CollectiveIdea::Acts::NestedSet](lib/awesome_nested_set/awesome_nested_set.rb) for more information.

## Options

You can pass various options to `acts_as_nested_set` macro. Configuration options are:

* `parent_column`: specifies the column name to use for keeping the position integer (default: parent_id)
* `primary_column`: specifies the column name to use as the inverse of the parent column (default: id)
* `left_column`: column name for left boundary data (default: lft)
* `right_column`: column name for right boundary data (default: rgt)
* `depth_column`: column name for the depth data default (default: depth)
* `scope`: restricts what is to be considered a list. Given a symbol, it'll attach `_id` (if it hasn't been already) and use that as the foreign key restriction. You can also pass an array to scope by multiple attributes. Example: `acts_as_nested_set :scope => [:notable_id, :notable_type]`
* `dependent`: behavior for cascading destroy. If set to :destroy, all the child objects are destroyed alongside this object by calling their destroy method. If set to :delete_all (default), all the child objects are deleted without calling their destroy method. If set to :nullify, all child objects will become orphaned and become roots themselves.
* `counter_cache`: adds a counter cache for the number of children. defaults to false. Example: `acts_as_nested_set :counter_cache => :children_count`
* `order_column`: on which column to do sorting, by default it is the left_column_name. Example: `acts_as_nested_set :order_column => :position`
* `touch`: If set to `true`, then the updated_at timestamp on the ancestors will be set to the current time whenever this object is saved or destroyed (default: false)

See [CollectiveIdea::Acts::NestedSet::Model::ClassMethods](/lib/awesome_nested_set/model.rb#L26) for a list of class methods and [CollectiveIdea::Acts::NestedSet::Model](lib/awesome_nested_set/model.rb#L13) for a list of instance methods added to acts_as_nested_set models

## Indexes

It is highly recommended that you add an index to the `rgt` column on your models. Every insertion requires finding the next `rgt` value to use and this can be slow for large tables without an index. It is probably best to index the other fields as well (`parent_id`, `lft`, `depth`).

## Callbacks

There are three callbacks called when moving a node:
`before_move`, `after_move` and `around_move`.

```ruby
class Category < ActiveRecord::Base
  acts_as_nested_set

  after_move :rebuild_slug
  around_move :da_fancy_things_around

  private

  def rebuild_slug
    # do whatever
  end

  def da_fancy_things_around
    # do something...
    yield # actually moves
    # do something else...
  end
end
```

Beside this there are also hooks to act on the newly added or removed children.

```ruby
class Category < ActiveRecord::Base
  acts_as_nested_set  :before_add     => :do_before_add_stuff,
                      :after_add      => :do_after_add_stuff,
                      :before_remove  => :do_before_remove_stuff,
                      :after_remove   => :do_after_remove_stuff

  private

  def do_before_add_stuff(child_node)
    # do whatever with the child
  end

  def do_after_add_stuff(child_node)
    # do whatever with the child
  end

  def do_before_remove_stuff(child_node)
    # do whatever with the child
  end

  def do_after_remove_stuff(child_node)
    # do whatever with the child
  end
end
```

## Protecting attributes from mass assignment (for Rails < 4)

It's generally best to "whitelist" the attributes that can be used in mass assignment:

```ruby
class Category < ActiveRecord::Base
  acts_as_nested_set
  attr_accessible :name, :parent_id
end
```

If for some reason that is not possible, you will probably want to protect the `lft` and `rgt` attributes:

```ruby
class Category < ActiveRecord::Base
  acts_as_nested_set
  attr_protected :lft, :rgt
end
```


## Add to your existing project

To make use of `awesome_nested_set`, your model needs to have 3 fields:
`lft`, `rgt`, and `parent_id`. The names of these fields are configurable.
You can also have optional fields, `depth` and `children_count`.

Create a migration to add fields:

```ruby
class AddNestedToCategories < ActiveRecord::Migration

  def self.up
    add_column :categories, :parent_id, :integer # Comment this line if your project already has this column
    # Category.where(parent_id: 0).update_all(parent_id: nil) # Uncomment this line if your project already has :parent_id
    add_column :categories, :lft,       :integer
    add_column :categories, :rgt,       :integer

    # optional fields
    add_column :categories, :depth,          :integer
    add_column :categories, :children_count, :integer

    # This is necessary to update :lft and :rgt columns
    Category.reset_column_information
    Category.rebuild!
  end

  def self.down
    remove_column :categories, :parent_id
    remove_column :categories, :lft
    remove_column :categories, :rgt

    # optional fields
    remove_column :categories, :depth
    remove_column :categories, :children_count
  end

end
```

Enable the nested set functionality by declaring `acts_as_nested_set` on your model

```ruby
class Category < ActiveRecord::Base
  acts_as_nested_set
end
```

Your project is now ready to run with the `awesome_nested_set` gem!


## Conversion from other trees

Coming from acts_as_tree or another system where you only have a parent_id? No problem. Simply add the lft & rgt fields as above, and then run:

```ruby
Category.rebuild!
```

Your tree will be converted to a valid nested set. Awesome!

Note: You can use `Category.rebuild!(false)` to skip model validations when performing the rebuild.

## View Helper

The view helper is called #nested_set_options.

Example usage:

```erb
<%= f.select :parent_id, nested_set_options(Category, @category) {|i| "#{'-' * i.level} #{i.name}" } %>

<%= select_tag 'parent_id', options_for_select(nested_set_options(Category) {|i| "#{'-' * i.level} #{i.name}" } ) %>
```

See [CollectiveIdea::Acts::NestedSet::Helper](lib/awesome_nested_set/helper.rb) for more information about the helpers.

## How to contribute

Please see the ['Contributing' document](CONTRIBUTING.md).

Copyright © 2008–2015 [Collective Idea](http://collectiveidea.com), released under the MIT license.
