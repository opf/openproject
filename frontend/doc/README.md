# Developing OpenProject Frontend

To keep watching the files in the frontend and process them on demand, use `npm run webpack`.
It will keep running a webpack instance with the `--watch` flag set.

Assets will be automatically loaded as part of the asset pipeline of Rails when you reload the server,
once webpack has completed.

## Living Style Guide

The style guide is available as part of the Rails development server at: <http://localhost:5000/styleguide>.

## Changing or updating Dependencies

We use `npm shrinkwrap` to lock down runtime (but not development)
dependencies. When adding or removing dependencies, please adhere to the
following workflow:

    npm install
    npm shrinkwrap

Please commit `npm-shrinkwrap.json` along with any changes to `package.json`.

## Topics

The individual topics for the documentation for the frontend are

1. `OVERVIEW.md` - a general overview on the folder structure and a general "what is where"
2. `BUILD.md` - notes on building the JavaScript for the asset pipeline
3. `TESTING.md` - documentation of our approach to integration and unit testing
4. `STYLING.md` - notes on styling and the Sass-Pipeline
5. `API.md` - notes on dealing with the several APIs provided by OpenProject
6. `RAILS.md` - an overview for the frontend parts still left in the Rails stack (mostly the JavaScript)
7. `MISC.md` - contains additional topics not fitting anywhere else
