Legacy Frontend in Rails
========================

__Important__: There are no explicit tests for the legacy frontend code - most of it is covered by Capybara based specs.

## `application.js.erb`

The manifest file hosts a plethora of additional JavaScript used throughout the application. It still maintains it's function as the original manifest used for the asset pipeline. 

If you really do have to add some JavaScript which ties into either 

- legacy views (i.e. non-`angular` views, of which there are plenty)
- component based JS (`tooltip.js` is an example)

you should create another JS file in `./app/assets/javascripts` and use the manifest as you would in any other Rails application.

The goal here should be to get rid of the JavaScript put directly into `application.js.erb`.

### Tie in with `angular`

The line between the original JavaScript and the "legacy" JavaScript is a little bit blurred, as there are cases where `jQuery` based JavaScript has to rely on existing `angular` behaviour and vice versa.

An example would be the use of the `AutoCompleteHelper` (see `./frontend/app/helpers/auto-complete-helper.js`) in the old WorkPackage form, after an HTML form has been loaded into the existing DOM after the user has decided to update the Work Package):

```javascript
//@see ./app/assets/javascripts/work_packages.js.erb
// the goal is to use the service for initializing atWho after a new piece of HTML has been inserted into the document

// the body is always the angular application on every page
var injector = angular.element('body').injector();

// the injecotr can be used to apply our service in arbitrary scopes
// NOTE: textareas is a collection of angular elements
injector.invoke(['AutoCompleteHelper', function(AutoCompleteHelper) {
    AutoCompleteHelper.enableTextareaAutoCompletion(textareas);
}]);
```

__Note__: In the above example, a scope is assumed for the elements passed to the service. The full implementation is a bit more esoteric, as one will have to manually create a `scope` around newly generated elements.

## Legacy views in Rails 

"Legacy views" are mostly views working with plain JavaScript, of which the most is found in `application.js.erb`.

Also, all of the plugins mainly use their own JavaScript to enable the functionality of their views.

The only views that currently rely on `angular` are:

- Work Packages List
- Timelines
- some private plugins

That should change over the course of development, especially to get rid of the `prototype.js` dependency.

Keep in mind, that there are places in the application where JavaScript code is safely stored away in a ruby method, an example would be the `ApplicationHelper`s own `user_specific_javascript_includes`.

A quick search for `jQuery` over all ruby files usually yields very good starting points and clues how and where to start refactoring.

## `protoype.js` and plugins

Prototype and some of it's related plugins are used in several of OpenProjects plugins. 

One extreme example is [`MyProjectPage`](https://github.com/finnlabs/openproject-my_project_page), which duplicates functionality from the core application. It uses [`Sortable`](http://madrobby.github.io/scriptaculous/sortable/) to achieve drag and drop functionality. It's a very old library (~2009) that is not maintained actively anymore.

Be that as it may, the `prototype.js` dependency cannot be fully removed as long as the plugins rely on it.

There are basically two approaches here:

1. Remove it completely and see what breaks
2. Move the `prototype.js` to the plugins that need it and remove the dependency from the core
