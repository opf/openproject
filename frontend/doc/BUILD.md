Building
========

All builds are put into Rails' asset pipeline. The actual build, i.e. merging all components together is done via [`webpack`](https://github.com/webpack/webpack).

It __is important to note__ that OpenProject currently still relies on the asset pipeline to serve the assets. Minification is __not__ done as part of webpack.

Two types of builds are performed, the first one is the OpenProject Standalone JS, which is not required by the Rails views per se. The second one is a bundle of global dependencies, which are necessary for the Rails views to run properly.

The configuration for building both global and standalone JS is found in `./frontend/webpack.config.js`

## Building OpenProject Standalone JS

The resulting output of this buildstep can be found in `./app/assets/javascripts/bundles/openproject-core-app.js`

This is done via `npm run webpack` (see `frontend/package.json`). The actual entrypoint for this is `./frontend/app/openproject-app.js`.

It contains only the the JavaScript needed for the AngularJS based part of the codebase (and `lodash`).

## Building globals

The resulting output of this buildstep can be found in `./app/assets/javascripts/bundles/openproject-global.js`. 

This is also built with `npm run webpack`. The actual entrypoint for this is `./frontend/app/global.js`

It contains all of the JavaScript necessary for the rails based views, like parts of `jQuery.ui`, but also `angular` itself.

## Building Sass

The Sass files in the rails stack are handled as one would expect: They are precompiled into one `default-*.css` for production and are reloaded on demand during development. The manifest for this can be found in `./app/assets/stylesheets/defaults.css.sass`.

### Important note on Frameworks:

OpenProject relies on the [Foundation for Apps Framework](http://foundation.zurb.com/apps), as well as one the [Bourbon Mixin Library](http://bourbon.io/). 

On the Rails side, both frameworks are included as gems - see the `./Gemfile` - and plugged directly into Rails' asset pipeline.

## Living Styleguide

The styleguide is rendered as part of the Rails stack at `/styleguide` (`RAILS_ENV=development` only). Please see [their GitHub](https://github.com/livingstyleguide/livingstyleguide) for more information.
