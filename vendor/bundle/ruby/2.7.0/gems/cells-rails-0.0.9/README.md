# Cells::Rails

[Cells](https://github.com/apotonick/cells) is a generic view model implementation for Ruby. Cells-rails brings Rails-specific bindings.

## Rails Features

* All asset-related helpers are now simply delegated to the global asset helper instance. This happens by automatically including `Cell::Helper::AssetHelper` into `ViewModel`.
* The global controller is passed to all cells via the context object. It's available via `ViewModel#controller`.
* `ViewModel#call` and `Collection#call` are automatically `html_safe`ed.


## Installation

Note that `cells-rails` is designed to work with Cells >= 4.1.

Add this line to your application's Gemfile and keep it real:

```ruby
gem 'cells-rails'
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).