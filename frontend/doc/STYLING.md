Styling the frontend
====================

Frontend styling is coupled to the Living Styleguide. The guide implements the same CSS that the usual frontend does. It takes the very same Sass files used in the Asset pipeline to build a second css file that is then used for diplaying the guide.

## Building

The guide is built via the the `gulp` stack.

The task involved is `gulp styleguide`, which is also part of `gulp watch` and can therefore be executed during `gulp dev`.

`gulp dev` will also start a static server delivering the assets for the styleguide (in contrast to `gulp styleguide`). As long as `gulp dev` runs, the styleguide will be available here:

```
http://localhost:8080/assets/css/styleguide.html
```

The static server will serve the whole `./frontend/public` folder, however, `styleguide.html` is the index for the styleguide.

## Using the styleguide

The styleguide itself is just a long html page demonstrating the components. It can be modified by altering its base file `styleguide.jade` (see `./frontend/app/assets/styleguide.jade`).

### Getting JavaScript to work with the Styleguide

In an ideal world, the styleguide would convey only styling-related information. Unfortunately, for practical purposes such as styling `ui.select`, which require some JavaScript to be active, the styleguide intorduces some custom JavaScript:

```jade
//from styleguide.jade
script(src='/assets/bundles/openproject-global.js')
script.
  angular.module('openproject-style-guide', ['ui.select', 'ngSanitize'])
```

The styleguide defines and initializes its own `angular.module`, which can be injected with various dependencies. The `ng-app` is present for all of the styleguide (attached to `body`).

__Note on magic__: The static server can actually serve `/assets/bundles/openproject-global.js` because of a line in `./frontend/server.js`:

```javascript
app.use('/assets', express.static(railsRoot + '/app/assets/javascripts'));
app.use('/assets', express.static(railsRoot + '/app/assets/images'));
```

which enables asset serving from the respective Rails directories.

If you want to add more JavaScript to it, you can directly include it in the `styleguide.jade`, but it is ill-advised. The styleguide should be used for the styling of the rendered output and not necessarily display functionality, mostly to avoid duplication of code (use a test to demonstrate functionality!).

## A note on the css style used

Originally introduced by @myabc, Sass-Code should ideally follow a convention as described in [Simple naming for CSS class names](http://www.hagenburger.net/BLOG/Modular-CSS-Class-Names.html).

So far, we mostly used Sass partials, grouped by their component, however, there is still a lot of legacy code in there, especially in the plugins. The legacy code for the core can be found within `./app/assets/stylesheets/_misc_legacy.sass`
