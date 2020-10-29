# date_validator [![Build Status](https://travis-ci.org/codegram/date_validator.png?branch=master)](https://travis-ci.org/codegram/date_validator)


A simple date validator for Rails. Should be compatible with all latest Rubies (~> 2.x).


```shell
$ gem install date_validator
```

And I mean simple. In your model:

```ruby
validates :expiration_date, date: true
```

or with some options, such as:

```ruby
validates :expiration_date,
          date: { after: Proc.new { Time.now },
                  before: Proc.new { Time.now + 1.year } }
# Using Proc.new prevents production cache issues
```

If you want to check the date against another attribute, you can pass it
a Symbol instead of a block:

```ruby
# Ensure the expiration date is after the packaging date
validates :expiration_date,
          date: { after: :packaging_date }
```

or access attributes via the object being validated directly (the input to the Proc):

```ruby
validates :due_date,
          date: { after_or_equal_to: Proc.new { |obj| obj.created_at.to_date }
# The object being validated is available in the Proc
```

For now the available options you can use are `:after`, `:before`,
`:after_or_equal_to`, `:before_or_equal_to` and `:equal_to`.

If you want to specify a custom message, you can do so in the options hash:

```ruby
validates :start_date,
  date: { after: Proc.new { Date.today }, message: 'must be after today' },
  on: :create
```

Pretty much self-explanatory! :)

If you want to make sure an attribute is before/after another attribute, use:

```ruby
validates :start_date, date: { before: :end_date }
```

If you want to allow an empty date, use:

```ruby
validates :optional_date, date: { allow_blank: true }
```
## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send us a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2013 Codegram. See LICENSE for details.
