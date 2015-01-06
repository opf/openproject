# Developing OpenProject Frontend

## Changing or updating Dependencies

We use `npm shrinkwrap` to lock down both development and runtime dependencies.
When adding or removing dependencies, please adhere to the following workflow:

    npm install
    npm shrinkwrap --dev
    ./scripts/clean-shrinkwrap.js

Please commit `npm-shrinkwrap.json` along with any changes to `package.json`.
