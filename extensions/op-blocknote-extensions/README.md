# OpenProject BlockNote extensions

[OpenProject](https://www.openproject.org/) extensions for the [BlockNote](https://www.blocknotejs.org/) editor.

## About this repo

This repo is split into two parts:

- The library itself, which is located in the `/lib` folder and can be built and packaged with `npm run build:lib`.
- A demo app, which is located in the `src/App.tsx` file and can be run locally with `npm run dev`.

## Usage

### Installation

Include the following entry to your _package.json_.

```json
"op-blocknote-extensions": "https://github.com/opf/op-blocknote-extensions/releases/download/<VERSION>/op-blocknote-extensions-<VERSION>.tgz"
```

(please note: at the time being, you need to replace the version in two places of the url.)

### Implementation

First thing is to initialize the library configuration...

```js
  initOpenProjectApi({ baseUrl: "https://my.openproject.url" });
```

... then setup a blocknote schema extending it with blocks offered by this library...

```jsx
  const schema = BlockNoteSchema.create().extend({
    blockSpecs: {
      "openProjectWorkPackage": openProjectWorkPackageBlockSpec(),
    },
  });
  type EditorType = typeof schema.BlockNoteEditor;

  const editor = useCreateBlockNote({ schema });
```

... same for slash menus ...

```jsx
  const getCustomSlashMenuItems = (editor: EditorType) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      openProjectWorkPackageSlashMenu(editor),
    ];
  };
```

... and include them all in a BlockNote instance

```jsx
  return (
    <BlockNoteView editor={editor}>
      <SuggestionMenuController
        triggerCharacter="/"
        getItems={async (query: string) =>
          filterSuggestionItems(getCustomSlashMenuItems(editor), query)
        }
      />
    </BlockNoteView>
  );
```

There's a working example in the [src/App.tsx](src/App.tsx) in this repository. You can test it locally by running:

```sh
npm run dev
```

Which will start a vite server with a BlockNote editor instance including the available extensions.

## Components in this library

|Component|Description|
|--|--|
|WorkPackage block|Search and display elegantly work package links|
|...|...|

## Build

To build the library and generate types and source maps. This will update the `dist` folder.

```sh
npm run build:lib
```

To develop with OpenProject locally

```sh
npm run build:lib
npm pack
cp op-blocknote-extensions-<VERSION>.tgz ../openproject/frontend
cd ../openproject/frontend
npm i -S op-blocknote-extensions-<VERSION>.tgz
```

This should make sure that the package is available for OpenProject even if running on a container.

### Releases

Updating the version field in package.json will automatically create a new Git tag with the corresponding version. Pushing this tag to the repository triggers the generation of a new release.

To publish a new release, simply update the version in package.json and merge the changes into the main branch.
