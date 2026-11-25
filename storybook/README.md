# Storybook (experiment)

Storybook as an alternative UI to Lookbook. Stories render existing
`ViewComponent::Preview` examples through Rails, so there is one source of
previews and Storybook only adds controls, docs and the Figma design panel.

```
Storybook :6006 ──(vite proxy /storybook, /assets, /api)──> Rails :3000
  .storybook/preview.ts                                    StorybookPreviewsController
    beforeAll: GET /storybook/assets  ─────────────────────> include_frontend_assets (once)
    loader:    GET /storybook/previews/<preview>/<example>?<args>
                                      ─────────────────────> preview HTML fragment, no layout
```

Query string args are cast to the type of the preview method's keyword
default (`scheme: :default` → Symbol, `block: false` → boolean).

## Run

Needs Rails (with Lookbook enabled, the default in development) and the
Angular dev server (`npm run serve` in `frontend/`, or `bin/dev`).

```sh
cd storybook
npm install
npm run storybook                                   # http://localhost:6006
OPENPROJECT_URL=http://localhost:3001 npm run storybook   # other Rails port
```

## Limits found

- Only `ViewComponent::Preview` subclasses render. 69 of the 90 previews in
  `lookbook/previews` subclass `Lookbook::Preview`, which Lookbook renders
  itself.
- Stories and their controls are written by hand; Lookbook derives them from
  `@param` tags.
- The Figma panel (`@storybook/addon-designs`) needs a URL with a file-name
  segment (`/design/<key>/<name>?node-id=…`) and a Figma session the embed can
  use.
