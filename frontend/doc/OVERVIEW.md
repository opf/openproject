Development overview
====================

This should give an idea about the contents of the `./frontend` folder. Most of what you find here is an amalgamation of [AngularJS](https://angularjs.org) and `jQuery`, as well as a good list of libraries used to ease the process of development.

This is the general structure (to a depth of 3 folders):

```
├── app
│   ├── api
│   ├── assets
│   ├── config
│   ├── helpers
│   ├── layout
│   │   └── controllers
│   ├── messages
│   │   └── controllers
│   ├── misc
│   ├── models
│   ├── services
│   ├── templates
│   │   ├── components
│   │   ├── layout
│   │   ├── timelines
│   │   └── work_packages
│   ├── time_entries
│   │   └── controllers
│   ├── timelines
│   │   ├── controllers
│   │   ├── directives
│   │   ├── helpers
│   │   ├── models
│   │   └── services
│   ├── ui_components
│   │   ├── date
│   │   └── filters
│   └── work_packages
│       ├── config
│       ├── controllers
│       ├── directives
│       ├── filters
│       ├── helpers
│       ├── models
│       ├── services
│       ├── tabs
│       └── view_models
├── doc
├── public
│   └── assets
│       └── css
├── scripts
└── tests
    └── unit
        ├── factories
        ├── lib
        ├── mocks
        ├── reports
        └── tests
```

## The `app` folder

This can be considered the main `src` folder. It contains all of the production relevant code for excuting the individual parts of the frontend. It does __not__ contain the test code.

The `app` folder is furthermore divided into:

* `work_packages` contains all the specific sources for the Work Package list and the attached details pane, as well as the full screen view
* `timelines` contains all code necessary for project timelines
* `time_entries` contains a single controller used in the timelog views 
* all the rest of the folders containing common components divided by their type

The common components are divided into their usual use cases and are available to every other module partaking in the build process.

## Using `index.js` to define modules

Most directories contain an `index.js` defining what is actually required in the build process. The `index.js` can be seen as a manifest defining what gets included and what not. _However_ this is slightly misleading, as the code in `index.js` is actually functional, defining many `angular` modules.

### Example: `timeEntries`

The initial file is located at `./frontend/app/time_entries/index.js` for which the module necessary is actually defined in `/frontend/app/openproject-app.js`

The file itself just requires `./controllers`, which is the directory next to it. `webpack` will look into the folder, look up the next `index.js` (`./frontend/app/time_entries/controllers/index.js`) and add the contents of that file:

```javascript
angular.module('openproject.timeEntries.controllers')
  .controller('TimeEntriesController', ['$scope', '$http', 'PathHelper',
    'SortService', 'PaginationService',
    require('./time-entries-controller')
  ]);
```

The file consists of a single module definition, that requires another file (`./frontend/app/time_entries/controllers/time-entries-controller.js`), which contains the actual controller function.

The files follow the __Asynchronous Module Defintion__ (AMD), so the different parts of the application can be isolated.

This makes planning the injections a bit harder, as they are spread out over two files (the `$injector` definition being in the respective `index.js`, the actual function signature being in the module itself.)

## Template handling in `./frontend/app/templates`

Out of the box, `angular` will offer asynchronous template loading from a URL. given a directive `testDirective`, the usual implementation could look like this:

```javascript
angular.module('foo')
    .directive('testDirective', function() {
        return {
            replace: true,
            templateUrl: '/templates/foo/test-directive.html',
            link: function(scope, element, attrs, ctrl) {
                /* here be dragons */ 
            }
        }
    })
```

In this example, what would usually happen during compilation is the asynchronous loading of `/templates/foo/test-directive.html`. 

As there are quite a few directives, the OpenProject frontend prevents the request to the server by using `angular.$templateCache`. 

As part of the webpack step (`npm run webpack`), templates are compiled as JS and put alongside the rest of the code in `openproject-core-app.js`. The `loader` for the templates can be found in `./frontend/webpack.config.js` which is dependent on [`ngtemplate-loader`](https://github.com/WearyMonkey/ngtemplate-loader).

