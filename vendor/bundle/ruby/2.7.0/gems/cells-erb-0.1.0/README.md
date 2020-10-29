# Cells::Erb

ERB support for Cells using [Erbse](https://github.com/apotonick/erbse).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cells-erb'
```

This will register `Erbse::Engine` with Tilt for `.erb` files.

And that's all you need to do.

## Erbse

[Erbse](https://github.com/apotonick/erbse) is the next-generation implementation of ERB that comes with some nice new semantics and explicit code. It does not use instance variables for output buffering.

You should read its docs to learn what you can and can't do with Erbse.

## Concat

The global `#concat` helper is not supported in Cells-ERB. Erbse uses local variables as output buffers, hence this global state helper does not work. Please use explicit string concatenation instead.

Instead of

```ruby
concat content_tag(:p, "Good")
concat "Morning!"
```

you can do

```ruby
content_tag(:p, "Good") + "Morning!"
```

## Block Yielding

With Erbse, you can actually [capture blocks](https://github.com/apotonick/erbse#block-yielding), pass them to other cells and `yield` them. This will simply return whatever the block returns, no weird buffer magic will be happening in the background.

## Capture

The `capture` implementation in Cells-ERB is literally a `yield`.

```ruby
def capture(&block)
  yield
end
```

If you want to capture a block of code without outputting it, you need to use Erbse's `<%@ %>` tag.

```erb
<%@ content = capture do %>
  <h1>Hi!</h1>
  It's <%= Time.new %>'o clock.
<% end %>
```

The `content` variable will now contain the string `<h1>Hi!</h1>\nIt's 23:37'o clock.`.

Use `c@pture` as a mnemonic for the correct tag, should you need this mechanic. `capture` is usually a smell of bad view design and should be avoided.

## HTML Escaping

Cells doesn't escape except when you tell it to do. However, you may run into problems when using Rails helpers. Internally, those helpers often blindly escape. This is not Cells' fault but a design flaw in Rails.

As a first step, try this and see if it helps.

```ruby
class SongCell < Cell::ViewModel
  include ActionView::Helpers::FormHelper
  include Cell::Erb # include Erb _after_ AV helpers.

  # ..
end
```

If that doesn't work, [read the docs](http://trailblazerb.org/gems/cells/cells4.html#html-escaping).

## Dependencies

This gem works with Tilt 1.4 and 2.0, and hence allows you to use it from Rails 3.2 upwards.
