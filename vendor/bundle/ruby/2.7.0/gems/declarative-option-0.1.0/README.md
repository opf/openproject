# Declarative::Option

_Dynamic options to evaluate at runtime._

## Installation

[![Gem Version](https://badge.fury.io/rb/mega-option.svg)](http://badge.fury.io/rb/mega-option)

Add this line to your application's Gemfile:

```ruby
gem 'mega-options'
```

Runs with Ruby >= 1.9.3.

# Option

Pass any value to `Option`, it will wrap it accordingly and make it executable, so you can call the value at runtime to evaluate it.

It works with static values.

```ruby
option = Declarative::Option(false)
option.(context, *args) #=> false
```

When passing in a `:symbol`, this will be treated as a method that's called on the context. The context is the first argument to `Option#call`.

```ruby
option = Declarative::Option(:object_id)
option.(Object.new, *args) #=> 2354383
```

Same with objects marked with `Callable`.

```ruby
class CallMe
  include Declarative::Callable

  def call(context, *args)
    puts "hello!"
  end
end

option = Declarative::Option(Callable.new) #=> "hello!"
```

And of course, with lambdas.

```ruby
option = Declarative::Option( ->(context, *args) { puts "yo!" } )
option.(context) #=> yo!
```

All `call` arguments behind the first are passed to the wrapped value.

# License

Copyright (c) 2017 by Nick Sutterer <apotonick@gmail.com>

Uber is released under the [MIT License](http://www.opensource.org/licenses/MIT).
