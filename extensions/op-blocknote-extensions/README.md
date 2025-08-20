# OpenProject BlockNote extensions

[OpenProject](https://www.openproject.org/) extensions for the [BlockNote](https://www.blocknotejs.org/) editor.

## Usage

First setup a blocknote schema with additional blocks offered by this library...

```jsx
  const schema = BlockNoteSchema.create({
    blockSpecs: {
      ...defaultBlockSpecs,
      openProjectWorkPackage: openProjectWorkPackageBlockSpec,
      dummy: dummyBlockSpec,
    },
  });
  const editor = useCreateBlockNote({ schema });
  type EditorType = typeof editor;
```

... setup slash menus ...

```jsx
  const getCustomSlashMenuItems = (editor: EditorType) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      ...getDefaultOpenProjectSlashMenuItems(editor),
    ];
  };
```

And include them all in a BlockNote instance

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

Releases and versioning are not implemented yet. For now the way to use this library is by including the following entry directly to the _package.json_ of your application.

```json
"op-blocknote-extensions": "github:opf/op-blocknote-extensions"
```
