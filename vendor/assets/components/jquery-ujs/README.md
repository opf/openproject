Unobtrusive scripting adapter for jQuery
========================================

This unobtrusive scripting support file is developed for the Ruby on Rails framework, but is not strictly tied to any specific backend. You can drop this into any application to:

- force confirmation dialogs for various actions;
- make non-GET requests from hyperlinks;
- make forms or hyperlinks submit data asynchronously with Ajax;
- have submit buttons become automatically disabled on form submit to prevent double-clicking.

These features are achieved by adding certain ["data" attributes][data] to your HTML markup. In Rails, they are added by the framework's template helpers.

Full [documentation is on the wiki][wiki], including the [list of published Ajax events][events].

Requirements
------------

- [jQuery 1.8.x or higher and less than 2.0][jquery];
- HTML5 doctype (optional).

If you don't use HTML5, adding "data" attributes to your HTML4 or XHTML pages might make them fail [W3C markup validation][validator]. However, this shouldn't create any issues for web browsers or other user agents.

Installation
------------

For automated installation in Rails, use the "jquery-rails" gem. Place this in your Gemfile:

```ruby
gem 'jquery-rails', '~> 2.1'
```

And run:

    $ bundle install

This next step depends on your version of Rails.

a. For Rails 3.1, add these lines to the top of your app/assets/javascripts/application.js file:

```javascript
//= require jquery
//= require jquery_ujs
```

b. For Rails 3.0, run this command:

*Be sure to get rid of the rails.js file if it exists, and instead use
the new jquery_ujs.js file that gets copied to the public directory.
Choose to overwrite jquery_ujs.js if prompted.*

    $ rails generate jquery:install

c. For Rails 2.x and for manual installation follow [this wiki](https://github.com/rails/jquery-ujs/wiki/Manual-installing-and-Rails-2) .

How to run tests
------------

Follow [this wiki](https://github.com/rails/jquery-ujs/wiki/Running-Tests-and-Contributing) to run tests .


[data]: http://www.w3.org/TR/html5/dom.html#embedding-custom-non-visible-data-with-the-data-*-attributes "Embedding custom non-visible data with the data-* attributes"
[wiki]: https://github.com/rails/jquery-ujs/wiki
[events]: https://github.com/rails/jquery-ujs/wiki/ajax
[jquery]: http://docs.jquery.com/Downloading_jQuery
[validator]: http://validator.w3.org/
[csrf]: http://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html
[adapter]: https://github.com/rails/jquery-ujs/raw/master/src/rails.js
