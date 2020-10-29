## 0.0.9

* Prevent Forwardable from printing warnings in Ruby 2.4+

## 0.0.8

* Fix testing for `rspec-cells` in combination with Rails 5.1. Thanks @tiagoamaro.

## 0.0.7

* Add `config.cells.include_template_engine = false` to turn off automatic
inclusion of, e.g., `Cell::Slim`.
* Require Cells >= 4.1.6.

## 0.0.6

* `Testing` fixed with Rails 5.

## 0.0.5

* Fix an annoying bundler loading bug. Thanks to @RKushnir.

## 0.0.4

* Fix `Cell::Translation`. Thanks to @zavan!

## 0.0.3

* `Cell::Helper::AssetHelper` is now always included and fixes https://github.com/apotonick/cells/issues/214 (hopefully).

## 0.0.2

* Moved all Rails files from `cells` to `cells-rails`.
