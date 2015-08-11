# Developing OpenProject Frontend

## Development server

To start the development server:

    gulp dev

## Living Style Guide

The style guide is available at: <http://localhost:8080/assets/css/styleguide.html>.

## Changing or updating Dependencies

We use `npm shrinkwrap` to lock down runtime (but not development)
dependencies. When adding or removing dependencies, please adhere to the
following workflow:

    npm install
    npm shrinkwrap
    ./scripts/clean-shrinkwrap.js

Please commit `npm-shrinkwrap.json` along with any changes to `package.json`.

## Topics

The individual topic for the documentation for the frontend are

1. `OVERVIEW.md` - a general overview on the folder structure and a general "what is where"
2. `BUILD.md` - notes on building the JavaScript for the asset pipeline
3. `TESTING.md` - documentation of our approach to integration and unit testing
4. `STYLING.md` - notes on styling and the Sass-Pipeline
5. `API.md` - notes on dealing with the several APIs provided by OpenProject
6. `RAILS.md` - an overview for the frontend parts still left in the Rails stack (mostly the JavaScript)
