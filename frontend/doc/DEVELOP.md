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
