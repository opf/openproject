Building
========

__Note__: All tasks involved are found in `./frontend/gulpfile.js`

All builds are put into Rails' asset pipeline. Builds are run via [`gulp`](http://gulpjs.com/). The actual build, i.e. merging all components together is done via [`webpack`](https://github.com/webpack/webpack).

It __is important to note__ that OpenProject currently still relies on the asset pipeline to serve the assets. Minification is done via `rake assets:precompile` and does __not__ happen in the `gulp` based pipeline.

Two types of builds are performed, the first one is the OpenProject Standalone JS, which is not required by the Rails views per se. The second one is a bundle of global dependencies, which are necessary for the Rails views to run properly.

The configuration for building both global and standalone JS is found in `./frontend/webpack.config.js`

## Building OpenProject Standalone JS

The resulting output of this buildstep can be found in `./app/assets/javascripts/bundles/openproject-core-app.js`

This is done via `gulp webpack` (see `gulpfile.js`, Line 63 ff.). The actual entrypoint for this is `./frontend/app/openproject-app.js`.

It contains only the the JavaScript needed for the AngularJS based part of the codebase (and `lodash`).

## Building globals

The resulting output of this buildstep can be found in `./app/assets/javascripts/bundles/openproject-global.js`. 

This is done via `gulp webpack` (see `gulpfile.js`, Line 63 ff.). The actual entrypoint for this is `./frontend/app/global.js`

It contains all of the JavaScript necessary for the rails based views, like parts of `jQuery.ui`, but also `angular` itself.

## Building Sass

Sass files are built via `gulp sass`, which handles the main Sass file from the Rails stack at `./app/assets/stylesheets/defaults.css.sass`, performs transformations on it and outputs the result to `./frontend/public/assets`. It __is important__ to note, that this serves __not__ the compilation of Sass for production purposes but is mostly for the availability of the CSS for the Living Styleguide. 

The Sass files in the rails stack are handled as one would expect: They are precompiled into one `default-*.css` for production and are reloaded on demand during development. The manifest for this can be found in `./app/assets/stylesheets/defaults.css.sass`.

### Important note on Frameworks:

OpenProject relies on the [Foundation for Apps Framework](http://foundation.zurb.com/apps), as well as one the [Bourbon Mixin Library](http://bourbon.io/). 

They are provided via LoadPath manipulation in the `gulp` based pipeline.The two frameworks are included as  `bower` components (see `./frontend/bower.json`).

On the Rails side, both frameworks are included as gems - see the `./Gemfile` - and plugged directly into Rails' asset pipeline.

## Misc Tasks

The build pipeline is also responsible for building the [Living Styleguide](https://github.com/livingstyleguide/livingstyleguide), relying heavily on the duplicated functionality of the `gulp` tasks revolving around Sass compilation
