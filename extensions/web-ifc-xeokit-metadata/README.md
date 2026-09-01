# web-ifc-xeokit-metadata

A small CLI that extracts the spatial hierarchy of an IFC file as
xeokit-sdk-compatible metadata JSON.

It is the in-monorepo successor to the .NET-based
[`opf/xeokit-metadata`](https://github.com/opf/xeokit-metadata) (a fork of
[`bimspot/xeokit-metadata`](https://github.com/bimspot/xeokit-metadata)).
Built on [`web-ifc`](https://github.com/ThatOpen/engine_web-ifc), which:

- supports IFC2x3, IFC4 and IFC4x3 (incl. Add2);
- requires only Node.js at runtime (no .NET, no Python);
- is actively maintained by That Open Company.

## Usage

```bash
web-ifc-xeokit-metadata path/to/model.ifc path/to/model.json
```

The output JSON matches the schema produced by the previous .NET tool and is
consumed by `gltf2xkt` in the BIM conversion pipeline (see
`modules/bim/app/services/bim/ifc_models/view_converter_service.rb`).

## Development

```bash
npm install
npm run dev   # tsx watch on src/index.ts
npm test      # vitest
npm run lint
```

## Test fixtures

See [`test/fixtures/README.md`](test/fixtures/README.md) for the source and
license of every `.ifc` file shipped in this repository.
