# Stringex [<img src="https://codeclimate.com/github/rsl/stringex.svg" />](https://codeclimate.com/github/rsl/stringex) [<img src="https://travis-ci.org/rsl/stringex.svg?branch=master" alt="Build Status" />](https://travis-ci.org/rsl/stringex) [<img src="https://badge.fury.io/rb/stringex.svg" alt="Gem Version" />](http://badge.fury.io/rb/stringex)

Some [hopefully] useful extensions to Ruby's String class. It is made up of three libraries: ActsAsUrl, Unidecoder, and StringExtensions.

*NOTE: Stringex 2.0 [and beyond] drops support for Rails 2. If you need support for that version, use 1.5.1 instead.*

## ActsAsUrl

*NOTE: You can now require 'stringex_lite' instead of 'stringex' and skip loading ActsAsUrl functionality if you don't need it.*

This library is designed to create URI-friendly representations of an attribute, for use in generating urls from your attributes. Basic usage is just calling the method:

```ruby
# Inside your model
acts_as_url :title
```

which will populate the `url` attribute on the object with the converted contents of the `title` attribute. `acts_as_url` takes the following options:

| | |
|---|---|
| `:url_attribute` | The name of the attribute to use for storing the generated url string. Default is `:url` |
| `:scope` | The name of model attribute to scope unique urls to. There is no default here. |
| `:only_when_blank` | If set to true, the url generation will only happen when `:url_attribute` is blank. Default is false (meaning url generation will happen always). |
| `:sync_url` | If set to true, the url field will be updated when changes are made to the attribute it is based on. Default is false. |
| `:allow_slash` | If set to true, the url field will not convert slashes. Default is false. |
| `:allow_duplicates` | If set to true, unique urls will not be enforced. Default is false. *NOTE: This is strongly not recommended if you are routing solely on the generated slug as you will no longer be guaranteed to lookup the expected record based on a duplicate slug.* |
| `:limit` | If set, will limit length of url generated. Default is nil. |
| `:truncate_words` | Used with :limit. If set to false, the url will be truncated to the last whole word before the limit was reached. Default is true. |
| `:blacklist` | List of urls that should not be allowed. Default is `%w{new}` [which avoids confusion on urls like `/documents/new`]. |
| `:blacklist_policy` | Proc or lambda defining new naming behavior when blacklisted urls are encountered. Default converts `/documents/new` to `/documents/new-document`. |

In order to use the generated url attribute, you will probably want to
override `to_param` like so, in your Model:

```ruby
# Inside your model
def to_param
  url # or whatever you set :url_attribute to
end
```

Routing called via named routes like `foo_path(@foo)` will automatically use the url. In your controllers you will need to call
`Foo.find_by_url(params[:id])` instead of the regular find. Don't look for `params[:url]` unless you set it explicitly in the routing, `to_param` will generate `params[:id]`.

Note that if you add `acts_as_url` to an existing model, the `url` database column will initially be blank. To set this column for your existing instances, you can use the `initialize_urls` method. So if your class is `Post`, just say `Post.initialize_urls`.

Unlike other permalink solutions, ActsAsUrl doesn't rely on Iconv (which is inconsistent across platforms and doesn't provide great transliteration as is) but instead uses a transliteration scheme (see the code for Unidecoder) which produces much better results for Unicode characters. It also mixes in some custom helpers to translate common characters into a more URI-friendly format rather than just dump them completely. Examples:

```ruby
# A simple prelude
"simple English".to_url => "simple-english"
"it's nothing at all".to_url => "its-nothing-at-all"
"rock & roll".to_url => "rock-and-roll"

# Let's show off
"$12 worth of Ruby power".to_url => "12-dollars-worth-of-ruby-power"
"10% off if you act now".to_url => "10-percent-off-if-you-act-now"

# You dont EVEN wanna rely on Iconv for this next part
"kick it en Français".to_url => "kick-it-en-francais"
"rock it Español style".to_url => "rock-it-espanol-style"
"tell your readers 你好".to_url => "tell-your-readers-ni-hao"
```

Compare those results with the ones produced on my Intel Mac by a leading permalink plugin:

```ruby
"simple English" # => "simple-english"
"it's nothing at all" # => "it-s-nothing-at-all"
"rock & roll" # => "rock-roll"

"$12 worth of Ruby power" # => "12-worth-of-ruby-power"
"10% off if you act now" # => "10-off-if-you-act-now"

"kick it en Français" # => "kick-it-en-francais"
"rock it Español style" # => "rock-it-espan-ol-style"
"tell your readers 你好" # => "tell-your-readers"
```

Not so great, actually.

Note: No offense is intended to the author(s) of whatever plugins might produce such results. It's not your faults Iconv sucks.

## Unidecoder

This library converts Unicode [and accented ASCII] characters to their plain-text ASCII equivalents. This is a port of Perl's Unidecode and provides eminently superior and more reliable results than Iconv. (Seriously, Iconv... A plague on both your houses! [sic])

You may require only the unidecoder (and its dependent localization) via

```ruby
require "stringex/unidecoder"
```

You probably won't ever need to run Unidecoder by itself. Thus, you probably would want to add String#to_ascii which wraps all of Unidecoder's functionality, by requiring:

```ruby
require "stringex/core_ext"
```

For anyone interested, details of the implementation can be read about in the original implementation of [Text::Unidecode](http://interglacial.com/~sburke/tpj/as_html/tpj22.html). Extensive examples can be found in the tests.

## StringExtensions

A small collection of extensions on Ruby's String class. Please see the documentation for StringExtensions module for more information. There's not much to explain about them really.

## Localization

With Stringex version 2.0 and higher, you can localize the different conversions in Stringex. Read more [here](https://github.com/rsl/stringex/wiki/Localization-of-Stringex-conversions). If you add a new language, please submit a pull request so we can make it available to other users also.

## Ruby on Rails Usage

When using Stringex with Ruby on Rails, you automatically get built-in translations for miscellaneous characters, HTML entities, and vulgar fractions. You can see Stringex's standard translations [here](https://github.com/rsl/stringex/tree/master/locales).

Currently, built-in translations are available for the following languages:

* English (en)
* Danish (da)
* Swedish (sv)
* Dutch (nl)
* German (de)
* Polish (pl)
* Portuguese Brazilian (pt-BR)
* Russian (ru)

You can easily add your own or customize the built-in translations - read [here](https://github.com/rsl/stringex/wiki/Localization-of-Stringex-conversions). If you add a new language, please submit a pull request so we can make it available to other users also.

If you don't want to use the Stringex built-in translations, you can force Stringex to use English (or another language), regardless what is in your `I18n.locale`. In an initializer, e.g. `config/initializers/stringex.rb`:

```ruby
Stringex::Localization.locale = :en
```

## CanCan Usage Note

You'll need to add a `:find_by => :url` to your `load_and_authorize_resource`. Here's an example:

```ruby
load_and_authorize_resource :class => "Whatever", :message => "Not authorized", :find_by => :url
```

## Semantic Versioning

This project conforms to [semver](http://semver.org/). As a result of this policy, you can (and should) specify a dependency on this gem using the [Pessimistic Version Constraint](http://guides.rubygems.org/patterns/) with two digits of precision. For example:

```ruby
spec.add_dependency 'stringex', '~> 1.0'
```

This means your project is compatible with licensee 1.0 up until 2.0. You can also set a higher minimum version:

```ruby
spec.add_dependency 'stringex', '~> 1.1'
```

## Thanks & Acknowledgements

If it's not obvious, some of the code for ActsAsUrl is based on Rick Olsen's [permalink_fu](http://svn.techno-weenie.net/projects/plugins/permalink_fu/) plugin. Unidecoder is a Ruby port of Sean Burke's [Text::Unidecode](http://interglacial.com/~sburke/tpj/as_html/tpj22.html) module for Perl. And, finally, the bulk of [strip_html_tags](classes/Stringex/StringExtensions.html#M000005) in StringExtensions was stolen from Tobias Lütke's Regex in [Typo](http://typosphere.org/).

GIANT thanks to the many contributors who have helped make Stringex better and better: http://github.com/rsl/stringex/contributors

Copyright (c) 2008-2018 Lucky Sneaks, released under the MIT license
