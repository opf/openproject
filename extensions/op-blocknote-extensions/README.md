# OpenProject BlockNote extensions

This repo is in an early prototype state.

### Usage

To build the library and generate types and source maps.

```sh
npm run build:lib
```

To run the test app for local development

```sh
npm run dev
```

To develop with OpenProject locally

```sh
npm run build:lib
npm pack
cp op-blocknote-extensions-0.0.0.tgz ../openproject/frontend
cd ../openproject/frontend
npm i -S op-blocknote-extensions-0.0.0.tgz
```

This should make sure that the package is available for OpenProject even if running on a container.
