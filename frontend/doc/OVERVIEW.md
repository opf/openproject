Development overview
====================

This should give an idea about the contents of the `./frontend` folder. Most of what you find here is an amalgamation of [AngularJS](https://angularjs.org) and JQuery, as well as a good list of libraries used to ease the process of development.

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
    ├── integration
    │   ├── mocks
    │   ├── pages
    │   └── specs
    └── unit
        ├── factories
        ├── lib
        ├── mocks
        ├── reports
        └── tests
```

## The `app` folder

This is where most of the magic happens. Contains all of the production relevant code for excuting the individual parts of the frontend. Does __not__ contain the test code.

The `app` folder is furthermore divided into:

* `work_packages` contains all the specific sources for the Work Package list and the attached details pane, as well as the full screen view
* `timelines` contains all code necessary for project timelines
* `time_entries` contains a single controller used in the timelog views 
* all the rest of the folders containing common components divided by their type
