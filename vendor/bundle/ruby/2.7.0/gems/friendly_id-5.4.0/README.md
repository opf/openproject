[![Build Status](https://github.com/norman/friendly_id/workflows/CI/badge.svg)](https://github.com/norman/friendly_id/actions)
[![Code Climate](https://codeclimate.com/github/norman/friendly_id.svg)](https://codeclimate.com/github/norman/friendly_id)
[![Inline docs](http://inch-ci.org/github/norman/friendly_id.svg?branch=master)](http://inch-ci.org/github/norman/friendly_id)

# FriendlyId

**For the most complete, user-friendly documentation, see the [FriendlyId Guide](http://norman.github.io/friendly_id/file.Guide.html).**

FriendlyId is the "Swiss Army bulldozer" of slugging and permalink plugins for
Active Record. It lets you create pretty URLs and work with human-friendly
strings as if they were numeric ids.

With FriendlyId, it's easy to make your application use URLs like:

    http://example.com/states/washington

instead of:

    http://example.com/states/4323454


## Getting Help

Ask questions on [Stack Overflow](http://stackoverflow.com/questions/tagged/friendly-id)
using the "friendly-id" tag, and for bugs have a look at [the bug section](https://github.com/norman/friendly_id#bugs)

## FriendlyId Features

FriendlyId offers many advanced features, including:

 * slug history and versioning
 * i18n
 * scoped slugs
 * reserved words
 * custom slug generators

## Usage

Add this line to your application's Gemfile:

```ruby
gem 'friendly_id', '~> 5.2.4' # Note: You MUST use 5.0.0 or greater for Rails 4.0+
```

And then execute:

```shell
bundle install
```

Add a `slug` column to the desired table (e.g. `Users`)
```shell
rails g migration AddSlugToUsers slug:uniq
```

Generate the friendly configuration file and a new migration

```shell
rails generate friendly_id
```

Note: You can delete the `CreateFriendlyIdSlugs` migration if you won't use the slug history feature. ([Read more](https://norman.github.io/friendly_id/FriendlyId/History.html))

Run the migration scripts

```shell
rails db:migrate
```

Edit the `app/models/user.rb` file as the following:

```ruby
class User < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
end
```

Edit the `app/controllers/users_controller.rb` file and replace `User.find` by `User.friendly.find`

```ruby
class UserController < ApplicationController
  def show
    @user = User.friendly.find(params[:id])
  end
end
```

Now when you create a new user like the following:

```ruby
User.create! name: "Joe Schmoe"
```

You can then access the user show page using the URL http://localhost:3000/users/joe-schmoe.


If you're adding FriendlyId to an existing app and need to generate slugs for
existing users, do this from the console, runner, or add a Rake task:

```ruby
User.find_each(&:save)
```

## Bugs

Please report them on the [Github issue
tracker](http://github.com/norman/friendly_id/issues) for this project.

If you have a bug to report, please include the following information:

* **Version information for FriendlyId, Rails and Ruby.**
* Full stack trace and error message (if you have them).
* Any snippets of relevant model, view or controller code that shows how you
  are using FriendlyId.

If you are able to, it helps even more if you can fork FriendlyId on Github,
and add a test that reproduces the error you are experiencing.

For more inspiration on how to report bugs, please see [this
article](https://www.chiark.greenend.org.uk/~sgtatham/bugs.html).

## Thanks and Credits

FriendlyId was originally created by Norman Clarke and Adrian Mugnolo, with
significant help early in its life by Emilio Tagua. It is now maintained by
Norman Clarke and Philip Arndt.

We're deeply grateful for the generous contributions over the years from [many
volunteers](https://github.com/norman/friendly_id/contributors).

## License

Copyright (c) 2008-2016 Norman Clarke and contributors, released under the MIT
license.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
