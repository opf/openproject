## Articles

* [Migrating an ad-hoc URL slug system to FriendlyId](http://olivierlacan.com/posts/migrating-an-ad-hoc-url-slug-system-to-friendly-id/)
* [Pretty URLs with FriendlyId](http://railscasts.com/episodes/314-pretty-urls-with-friendlyid)

## Docs

The most current docs from the master branch can always be found
[here](http://norman.github.io/friendly_id).

Docs for older versions are also available:

* [5.0](http://norman.github.io/friendly_id/5.0/)
* [4.0](http://norman.github.io/friendly_id/4.0/)
* [3.3](http://norman.github.io/friendly_id/3.3/)
* [2.3](http://norman.github.io/friendly_id/2.3/)

## What Changed in Version 5.1

5.1 is a bugfix release, but bumps the minor version because some applications may be dependent
on the previously buggy behavior. The changes include:

* Blank strings can no longer be used as slugs.
* When the first slug candidate is rejected because it is reserved, additional candidates will
  now be considered before marking the record as invalid.
* The `:finders` module is now compatible with Rails 4.2.

## What Changed in Version 5.0

As of version 5.0, FriendlyId uses [semantic versioning](http://semver.org/). Therefore, as you might
infer from the version number, 5.0 introduces changes incompatible with 4.0.

The most important changes are:

* Finders are no longer overridden by default. If you want to do friendly finds,
  you must do `Model.friendly.find` rather than `Model.find`. You can however
  restore FriendlyId 4-style finders by using the `:finders` addon:

  ```ruby
  friendly_id :foo, use: :slugged # you must do MyClass.friendly.find('bar')
  # or...
  friendly_id :foo, use: [:slugged, :finders] # you can now do MyClass.find('bar')
  ```
* A new "candidates" functionality which makes it easy to set up a list of
  alternate slugs that can be used to uniquely distinguish records, rather than
  appending a sequence. For example:

  ```ruby
  class Restaurant < ActiveRecord::Base
    extend FriendlyId
    friendly_id :slug_candidates, use: :slugged

    # Try building a slug based on the following fields in
    # increasing order of specificity.
    def slug_candidates
      [
        :name,
        [:name, :city],
        [:name, :street, :city],
        [:name, :street_number, :street, :city]
      ]
    end
  end
  ```
* Now that candidates have been added, FriendlyId no longer uses a numeric
  sequence to differentiate conflicting slug, but rather a UUID (e.g. something
  like `2bc08962-b3dd-4f29-b2e6-244710c86106`). This makes the
  codebase simpler and more reliable when running concurrently, at the expense
  of uglier ids being generated when there are conflicts.
* The default sequence separator has been changed from two dashes to one dash.
* Slugs are no longer regenerated when a record is saved. If you want to regenerate
  a slug, you must explicitly set the slug column to nil:

  ```ruby
  restaurant.friendly_id # joes-diner
  restaurant.name = "The Plaza Diner"
  restaurant.save!
  restaurant.friendly_id # joes-diner
  restaurant.slug = nil
  restaurant.save!
  restaurant.friendly_id # the-plaza-diner
  ```

  You can restore some of the old behavior by overriding the
  `should_generate_new_friendly_id?` method.
* The `friendly_id` Rails generator now generates an initializer showing you
  how to do some common global configuration.
* The Globalize plugin has moved to a [separate gem](https://github.com/norman/friendly_id-globalize) (currently in alpha).
* The `:reserved` module no longer includes any default reserved words.
  Previously it blocked "edit" and "new" everywhere. The default word list has
  been moved to `config/initializers/friendly_id.rb` and now includes many more
  words.
* The `:history` and `:scoped` addons can now be used together.
* Since it now requires Rails 4, FriendlyId also now requires Ruby 1.9.3 or
  higher.

## Upgrading from FriendlyId 4.0

Run `rails generate friendly_id --skip-migration` and edit the initializer
generated in `config/initializers/friendly_id.rb`. This file contains notes
describing how to restore (or not) some of the defaults from FriendlyId 4.0.

If you want to use the `:history` and `:scoped` addons together, you must add a
`:scope` column to your friendly_id_slugs table and replace the unique index on
`:slug` and `:sluggable_type` with a unique index on those two columns, plus
the new `:scope` column.

A migration like this should be sufficient:

```ruby
add_column   :friendly_id_slugs, :scope, :string
remove_index :friendly_id_slugs, [:slug, :sluggable_type]
add_index    :friendly_id_slugs, [:slug, :sluggable_type]
add_index    :friendly_id_slugs, [:slug, :sluggable_type, :scope], unique: true
```
