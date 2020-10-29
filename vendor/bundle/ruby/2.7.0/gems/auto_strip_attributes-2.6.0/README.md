# AutoStripAttributes

AutoStripAttributes helps to remove unnecessary whitespaces from ActiveRecord or ActiveModel attributes.
It's good for removing accidental spaces from user inputs (e.g. when user copy/pastes some value to a form and the value has extra spaces at the end).

It works by adding a before_validation hook to the record. No other methods are added. Gem is kept as simple as possible.

Gem has option to set empty strings to nil or to remove extra spaces inside the string.

[![Build Status](https://travis-ci.org/holli/auto_strip_attributes.svg?branch=master)](https://travis-ci.org/holli/auto_strip_attributes)
[![Downloads](https://img.shields.io/gem/dt/auto_strip_attributes)](https://rubygems.org/gems/auto_strip_attributes/)
[![Gem](https://img.shields.io/gem/v/auto_strip_attributes)](https://rubygems.org/gems/auto_strip_attributes/)

## Howto / examples

Include gem in your Gemfile:

```ruby
gem "auto_strip_attributes", "~> 2.6"
```

Example ActiveRecord usage: 

```ruby
class User < ActiveRecord::Base

  # Normal usage where " aaa  bbb\t " changes to "aaa  bbb"
  auto_strip_attributes :nick, :comment

  # Squeezes spaces inside the string: "James     Bond  " => "James Bond"
  auto_strip_attributes :name, squish: true

  # Won't set to null even if string is blank. "   " => ""
  auto_strip_attributes :email, nullify: false

  # Won't set to null even if array is blank. ["   "] => []
  auto_strip_attributes :tags, nullify_array: false

  # Use with attributes that are not mapped to a column
  auto_strip_attributes :password, virtual: true
end
```

Example ActiveModel usage:

```ruby
class VirtualUser
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  extend AutoStripAttributes

  attr_accessor :email

  # Use the `virtual` option because attributes are not mapped to a column
  auto_strip_attributes :email, virtual: true
end

virtual_user = VirtualUser.new
virtual_user.email = " alice@example.com "

virtual_user.validate
virtual_user.email #=> "alice@example.com"

```

# Options
### Default options

By default the following options are defined (listed in the order of processing):

- `:strip` (enabled by default) - removes whitespaces from the beginning and the end of string. Works exactly same as `String#strip`, i.e., may not strip non-ASCII whitespaces.
- `:nullify` (enabled by default) - replaces empty strings with nil.
- `:nullify_array` (enabled by default) - replaces empty arrays with nil.
- `:squish` (disabled by default) - replaces all consecutive Unicode whitespace characters (including tabs and new lines) with single space (U+0020). Works exactly same as Rails `String#squish`
- `:delete_whitespaces` (disabled by default) - deletes all spaces (U+0020) and tabs (U+0009).
- `:convert_non_breaking_spaces` (disabled by default) - converts non-breaking spaces (U+00A0) to normal spaces (U+0020).
- `:virtual` (disabled by default) - By default `auto_strip_attributes` doesn't work with non-persistent attributes (e.g., attributes that are created with `attr_accessor`). This is to avoid calling their custom getter/setter methods. Use this option with non-persistent attributes.
- For more filters use custom filters (more examples at https://github.com/holli/auto_strip_attributes/wiki)

### Custom Filters

Gem supports custom filtering methods. Custom methods can be set by calling to set_filter method
inside a block passed to AutoStripAttributes::Config.setup. set_filter method accepts either Symbol or Hash as a
parameter. If parameter is a Hash, the key should be filter name and the value is boolean whether filter is enabled by
default or not. Block should return processed value. See examples of custom filters at https://github.com/holli/auto_strip_attributes/wiki

This is an example on how to add html tags stripping in Rails

```ruby

E.g. inside config/initializers/auto_strip_attributes.rb

AutoStripAttributes::Config.setup do
  set_filter(strip_html: false) do |value|
    ActionController::Base.helpers.strip_tags value
  end
end


And in the model:

class User < ActiveRecord::Base
  auto_strip_attributes :extra_info, strip_html: true
end

```

Change the order of filters is done by manipulating filters_order array. You may also enable or disable filter by
default by changing filters_enabled hash.

Example of making :strip_html filter first and enabling :squish by default

```ruby
AutoStripAttributes::Config.setup do
  filters_order.delete(:strip_html)
  filters_order.insert(0, :strip_html)
  filters_enabled[:squish] = true
end
```

AutoStripAttributes::Config.setup accepts following options

- :clear => true, to clear all filters
- :defaults => true, to set three default filters mentioned above


# Versions

- see https://github.com/holli/auto_strip_attributes/blob/master/CHANGELOG.md


# Requirements

Gem has been tested with newest Ruby & Rails combination and it probably works also with older versions. See test matrix at https://github.com/holli/auto_strip_attributes/blob/master/.travis.yml

[![Build Status](https://travis-ci.org/holli/auto_strip_attributes.svg?branch=master)](https://travis-ci.org/holli/auto_strip_attributes)

# Support

Submit suggestions or feature requests as a GitHub Issue or Pull Request. Remember to update tests. Tests are quite extensive.

# Other approaches

This gem works by adding before_validation hook and setting attributes with self[attribute]=stripped_value. See: https://github.com/holli/auto_strip_attributes/blob/master/lib/auto_strip_attributes.rb

Other approaches could include calling attribute= from before_validation. This would end up calling possible custom setters twice. Might not be desired effect (e.g. if setter does some logging).

Method chaining attribute= can be also used. But then stripping would be omitted if there is some code that calls model[attribute]= directly. This could happen easily when using hashes in some places.

### Similar gems

There are many similar gems. Most of those don't have :squish or :nullify options. Those gems
might have some extra methods whereas this gem is kept as simple as possible. These gems have a bit
different approaches. See discussion in previous chapter.

- https://github.com/phatworx/acts_as_strip
- https://github.com/rmm5t/strip_attributes
- https://github.com/thomasfedb/attr_cleaner
- https://github.com/mdeering/attribute_normalizer (Bit hardcore approach, more features and more complex)

# Licence

Released under the MIT license (http://www.opensource.org/licenses/mit-license.php)
