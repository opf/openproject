# Gon gem — get your Rails variables in your js

[![Join the chat at https://gitter.im/gazay/gon](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/gazay/gon?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

![Gon. You should try this. If you look closer - you will see an elephant.](https://github.com/gazay/gon/raw/master/doc/logo_small.png)

[![Build Status](https://travis-ci.org/gazay/gon.svg?branch=master)](https://travis-ci.org/gazay/gon) [![CodeClimate](https://codeclimate.com/github/gazay/gon/badges/gpa.svg)](https://codeclimate.com/github/gazay/gon)

If you need to send some data to your js files and you don't want to do this with long way through views and parsing - use this force!

Now you can easily renew data in your variables through ajax with [gon.watch](https://github.com/gazay/gon/wiki/Usage-gon-watch)!

With [Jbuilder](https://github.com/rails/jbuilder), [Rabl](https://github.com/nesquena/rabl), and [Rabl-Rails](https://github.com/ccocchi/rabl-rails) support!

For Sinatra available [gon-sinatra](https://github.com/gazay/gon-sinatra).

For .Net MVC available port [NGon](https://github.com/brooklynDev/NGon).

For elixir Phoenix available [PhoenixGon](https://github.com/khusnetdinov/phoenix_gon).

<a href="https://evilmartians.com/?utm_source=gon">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54">
</a>

## An example of typical use

### Very good and detailed example and reasons to use is considered in [railscast](http://railscasts.com/episodes/324-passing-data-to-javascript) by Ryan Bates

When you need to send some start data from your controller to your js
you might be doing something like this:

  1. Write this data in controller(presenter/model) to some variable
  2. In view for this action you put this variable to some objects by data
     attributes, or write js right in view
  3. Then there can be two ways in js:
    + if you previously wrote data in data
     attributes - you should parse this attributes and write data to some
     js variable.
    + if you wrote js right in view (many frontenders would shame you for
  that) - you just use data from this js - OK.
  4. You can use your data in your js

And every time when you need to send some data from action to js you do this.

With gon you configure it firstly - just put in layout one tag, and add
gem line to your Gemfile and do the following:

  1. Write variables by

   ``` ruby
    gon.variable_name = variable_value

    # or new syntax
    gon.push({
      :user_id => 1,
      :user_role => "admin"
    })

    gon.push(any_object) # any_object with respond_to? :each_pair
   ```

  2. In your js you get this by

   ``` js
    gon.variable_name
   ```

  3. profit?

With the `gon.watch` feature you can easily renew data in gon variables!
Simply call `gon.watch` from your js file. It's super useful
in modern web applications!

## Usage

### More details about configuration and usage you can find in [gon wiki](https://github.com/gazay/gon/wiki)

`app/views/layouts/application.html.erb`

``` erb
<head>
  <title>some title</title>
  <%= Gon::Base.render_data %>
  <!-- include your action js code -->
  ...
```

For rails 3:
``` erb
  <%= include_gon %>
  ...
```



You can pass some [options](https://github.com/gazay/gon/wiki/Options)
to `render_data` method.

You put something like this in the action of your controller:

``` ruby
@your_int = 123
@your_array = [1,2]
@your_hash = {'a' => 1, 'b' => 2}
gon.your_int = @your_int
gon.your_other_int = 345 + gon.your_int
gon.your_array = @your_array
gon.your_array << gon.your_int
gon.your_hash = @your_hash

gon.all_variables # > {:your_int => 123, :your_other_int => 468, :your_array => [1, 2, 123], :your_hash => {'a' => 1, 'b' => 2}}
gon.your_array # > [1, 2, 123]

# gon.clear # gon.all_variables now is {}
```

Access the variables from your JavaScript file:

``` js
alert(gon.your_int)
alert(gon.your_other_int)
alert(gon.your_array)
alert(gon.your_hash)
```

### AMD compatible version: `include_gon_amd`

If your site uses AMD modules you can use the `include_gon_amd` helper to
include the variables and watch function as a module. Options are mostly
the same as for `include_gon`, except for `namespace_check`, which does
nothing and `namespace`, which is used as the name of the defined module.
The end result will look somewhat like the following:

```js
define('yourNameSpace', [], function() {
  var gon = {};
  gon.yourVariable = yourValue;
  // etc...

  return gon;
});
```

A (very) simplified usage example:

`app/views/layouts/application.html.erb`

```ruby
include_gon_amd namespace: 'data'
```

`Some JavaScript module`

```js
define(['data'], function(data) {
  alert(data.myVariable);
});
```

## gon.watch - renew your data easily!

You can use gon for renewing your data without reloading pages and
writing long js functions! It's really great for some live values.

Supports `gon.watch.rabl` and `gon.watch.jbuilder` usage.

[Instruction](https://github.com/gazay/gon/wiki/Usage-gon-watch) for
usage gon.watch.

## Usage with Rabl

You can write your variables assign logic to templates with [Rabl](https://github.com/nesquena/rabl).
The way of writing Rabl templates is very clearly described in their repo.

Profit of using Rabl with gon:

  1. You can clean your controllers now!
  2. Work with database objects and collections clearly and easyly
  3. All power of Rabl
  4. You can still be lazy and don't use common way to transfer data in js
  5. And so on

[Instruction](https://github.com/gazay/gon/wiki/Usage-with-rabl) for
usage gon with Rabl.

## Usage with Rabl-Rails
`gon.rabl` works with [rabl-rails](https://github.com/ccocchi/rabl-rails). Learn to write RABL the rabl-rails way [here](https://github.com/ccocchi/rabl-rails).

Add gon and rabl-rails to your environment:
```ruby
gem 'gon'
gem 'rabl-rails'
```
Define a rabl template using rabl-rails syntax:
```rabl
#app/views/users/show.rabl
object :@user
attributes :id, :name, :email, :location
```
Call gon.rabl in your controller

```ruby
#app/controllers/users_controller.rb
def show
  @user = User.find(params[:id])
  gon.rabl
end
```

## Usage with Jbuilder

Use gon with [Jbuilder](https://github.com/rails/jbuilder) as with [Rabl](https://guthub.com/nesquena/rabl):

[Instruction](https://github.com/gazay/gon/wiki/Usage-with-jbuilder) for
usage gon with Jbuilder.

## gon.global

You can use gon for sending your data to js from anywhere! It's really
great for some init data.

[Instruction](https://github.com/gazay/gon/wiki/Usage-gon-global) for
usage gon.global.

## Speed up Gon

You can use any [JSON Engine](https://github.com/intridea/multi_json#supported-json-engines) you want.
Gon uses `MultiJson` with autodetect mode, so all you need is just require your JSON library.

## Contributors

* @gazay
* @takiy33

Special thanks to @brainopia, @kossnocorp and @ai.

## License

The MIT License

## Security Contact

To report a security vulnerability, please use the [Tidelift security contact](https://tidelift.com/security). Tidelift will coordinate the fix and disclosure.
