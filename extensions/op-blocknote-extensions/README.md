# OpenProject BlockNote extensions

[OpenProject](https://www.openproject.org/) extensions for the [BlockNote](https://www.blocknotejs.org/) editor.

## About this repo

This repo is split into two parts:

- The library itself, which is located in the `/lib` folder and can be built and packaged with `npm run build`.
- A demo app, which is located in the `src/App.tsx` file and can be run locally with `npm run dev`.

## Usage

### Compatibility

| OpenProject version | BlockNote extensions version |
|---|---|
| 17.9 | 0.3.0 |
| 17.8 | 0.2.3 | 

### Installation

Include the following entry to your _package.json_.

```json
"op-blocknote-extensions": "https://github.com/opf/op-blocknote-extensions/releases/download/<VERSION>/op-blocknote-extensions-<VERSION>.tgz"
```

(please note: at the time being, you need to replace the version in two places of the url.)

### Implementation

First, initialize the library configuration:

```js
initializeOpBlockNoteExtensions({ baseUrl: 'https://my.openproject.url', locale: 'en' });
```

`baseUrl` is the address of your OpenProject instance. It is used to build links
to work packages and to recognize pasted work package URLs.

Optionally, you can pass a `proxyUrl`. The authorized API requests are then sent
to that address instead of `baseUrl`, which is useful if the API traffic has to
be routed through a proxy, for example to inject authorization. Links to work
packages and the recognition of pasted work package URLs keep using `baseUrl`.

```js
initializeOpBlockNoteExtensions({
  baseUrl: 'https://my.openproject.url',
  proxyUrl: 'https://my.proxy.url',
  locale: 'en',
});
```

Optionally, you can pass a `projectId`: the numeric id of the project the edited document belongs to. The first work package created from the document opens on that project; afterwards the form opens on the project the last work package was created in, for as long as the same document stays open. Pass it wherever the surrounding application knows the project, and leave it out where the editor is not rendered in one.

```js
initializeOpBlockNoteExtensions({
  baseUrl: 'https://my.openproject.url',
  locale: 'en',
  projectId: 42,
});
```

Then set up a BlockNote schema extending it with the block and inline specs:

```tsx
const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
  },
});
type EditorType = typeof schema.BlockNoteEditor;
```

Create the editor:

```tsx
const editor = useCreateBlockNote({ schema });
```

Build the slash menu:

```tsx
const getSlashItems = useCallback(
  async (query: string) =>
    filterSuggestionItems(
      [
        ...getDefaultReactSlashMenuItems(editor),
        ...getOpenProjectSlashMenuItems(editor),
      ],
      query
    ),
  [editor]
);
```

`OpenProjectFormattingToolbar` is BlockNote's formatting toolbar with everything this library adds to it - currently a "Create work package" button on a text selection: the selected text names the work package, and the rich link for it takes the text's place in the document once it exists - a card where the selection hands over whole paragraphs, an inline chip within a line of text. It is offered for a selection that reads as a subject, so not for one that already holds a work package. Render it beside the editor and turn off the toolbar BlockNote brings itself, with `formattingToolbar={false}`.

Where the host has toolbar items of its own to place, compose the toolbar by hand with `useCreateWorkPackageFromSelection(editor)` instead: it hands back the button, for the children of `FormattingToolbar`, and the form, which has to stay outside the controller - BlockNote takes the toolbar away as soon as the selection is gone, and a form that was filled in must not go with it.

`getOpenProjectSlashMenuItems` returns every item this library offers: linking an existing work package, and creating a new one through a form and linking it. Both insert a card on an empty line and an inline chip within a line of text.

`OpenProjectHashMenu` is the `#` command for linking a work package: typing anything after the hash searches, and how many hashes stand before the query decides what the picked work package becomes - `#` a chip carrying its ID, `##` one that adds the type and the subject, `###` one that adds the status as well, and `####` a card of its own. Invoked within a line, `####` breaks the line around the card, the way resizing an inline link into a card does. A longer run of hashes is not a command and stays on screen as typed. Render it beside the editor.

Where the host builds the `#` menu itself, `useHashWpMenu(editor)` hands back the pieces instead: `getHashItems`, `HashWpMenu` and `shouldOpenHashMenu`. All three belong on the `SuggestionMenuController` - the last one is what keeps a run longer than `####` from searching.

The create form is built from the work package form endpoint of the API, so the attributes it asks for - and their labels - come from the OpenProject instance: subject, project, type, assignee, plus every other attribute the selected type requires. Attributes the API already has a default for (status and priority, for instance) are left to it and are not shown, required or not.

Include everything in a `BlockNoteView`:

```tsx
return (
  <BlockNoteView editor={editor} slashMenu={false} formattingToolbar={false}>
    <OpenProjectFormattingToolbar />
    <SuggestionMenuController
      triggerCharacter="/"
      getItems={getSlashItems}
    />
    <OpenProjectHashMenu />
  </BlockNoteView>
);
```

There's a working example in the [src/App.tsx](src/App.tsx) in this repository. You can test it locally by running:

```sh
npm run dev
```

Which will start a vite server with a BlockNote editor instance including the available extensions.

#### Usage within a shadow dom root

This project uses `styledComponents` to define styles. This means that styles are, by default, injected onto the page header. To be able to use styles onto a shadow dom root it is necessary to use our `ShadowDomWrapper` component targeting the root for the styles.

```tsx
<ShadowDomWrapper target={targetHtmlElementOrShadowRoot}>
  <MyBlockNoteView />
</ShadowDomWrapper>
```

### To run locally with valid API requests to an OpenProject instance

Step 1: Copy `.env.example` to `.env` and fill in:

- `VITE_OPENPROJECT_URL` — your OpenProject instance (e.g. `https://openproject.local`). Defaults to `http://localhost:3000` if unset.
- `VITE_API_KEY` — an API key generated at `https://openproject.local/my/access_tokens`.

Step 2: Enable CORS and add the dev origin (`http://localhost:5173`) at `https://openproject.local/admin/settings/api`.

Step 3: Start the development server — `npm run dev`.

## Components in this library

| Component            | Description                                        |
| -------------------- | -------------------------------------------------- |
| WorkPackage block    | Search and display elegantly work package links    |
| Create work package  | Create a work package from the document and link it |
| ...                  | ...                                                |

## Build

To build the library and generate types and source maps. This will update the `dist` folder.

```sh
npm run build
```

To develop with OpenProject locally

```sh
npm run build
npm pack
cp op-blocknote-extensions-*.tgz ../openproject/frontend
cd ../openproject/frontend
npm i -S op-blocknote-extensions-*.tgz
```

This should make sure that the package is available for OpenProject even if running on a container.

### Releases

To publish a new release, update the version in package.json and merge the changes into the release branch. This will generate a new Git tag according to the version and release a new version of the package.

For existing releases, see https://github.com/opf/op-blocknote-extensions/releases/.
