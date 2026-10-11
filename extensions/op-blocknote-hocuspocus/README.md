# op-blocknote-hocuspocus

[![Tests](https://github.com/opf/openproject/actions/workflows/hocuspocus-test.yml/badge.svg)](https://github.com/opf/openproject/actions/workflows/hocuspocus-test.yml)
[![Docker](https://github.com/opf/openproject/actions/workflows/hocuspocus-docker.yml/badge.svg)](https://github.com/opf/openproject/actions/workflows/hocuspocus-docker.yml)

A real-time collaborative editing server for [OpenProject](https://www.openproject.org/) documents, powered by [Yjs](https://github.com/yjs/yjs) and [Hocuspocus](https://tiptap.dev/docs/hocuspocus/introduction).

## Installation

### From Source

```bash
# Clone the OpenProject repository
git clone https://github.com/opf/openproject.git
cd openproject/extensions/op-blocknote-hocuspocus

# Install dependencies
npm install

# Start the server with the appropriate environment variables setup
SECRET=secret12345 npm run start
```

The `SECRET` environment variable is a shared value between this application and OpenProject. Make sure to configure the same value in OpenProject - Settings Hocuspocus secret and in the `SECRET` environment variable of this project.

### Using Docker

```bash
docker pull openproject/hocuspocus:latest

docker run -d \
  -p 1234:1234 \
  -e SECRET=secret12345 \
  openproject/hocuspocus:latest
```

## Configuration & Usage

### Configuration

#### `OPENPROJECT_URL` (default `undefined`)

This is the base URL hocuspocus will use to connect to OpenProject.
It is undefined by default, in which case the URL is derived from the edited resources (e.g. documents) in OpenProject.

This can fail in some cases where hocuspocus cannot reach the host under the given URL,
for instance when using the docker compose setup with `localhost` for the OpenProject host.
In this case hocuspocus would try to connect to itself.

To fix that you can configure `OPENPROJECT_URL` to 'rebase' the resource URLs to the given value.

For instance, in the case of docker compose:

```bash
OPENPROJECT_URL=http://web
```

Where `web` is the DNS name for the OpenProject container in the docker compose setup.

> When overriding the base URL like this, you also need to set `OPENPROJECT_ADDITIONAL__HOST__NAMES`
> on the OpenProject side. In the example above you would set it to `web`.

> When using `http` as the protocol as shown in the example, you also MUST set the `OPENPROJECT_HTTPS`
> option (see below) to `true`.

#### `OPENPROJECT_HTTPS` (default `undefined`)

This option only applies when using `OPENPROJECT_URL`.
It is a direct reflection of the HTTPS setting in OpenProject.
If this is true, hocuspocus will add the `X-Forwarded-Proto` header to its requests to prevent running into
https redirects.

```bash
OPENPROJECT_HTTPS=true
```

### HTTP API

Besides websocket connections for the editor, the server offers an HTTP API that OpenProject uses to read and edit
document content on behalf of MCP clients. Edits are applied to the live document, so they reach every connected editor
immediately.

Requests to the content endpoints authenticate with the same encrypted token the editor uses, sent as
`Authorization: Bearer <token>`. The token determines the document.

| Request                           | Description                                                                                       |
|-----------------------------------|---------------------------------------------------------------------------------------------------|
| `GET /api/v1/documents/schema`    | JSON schema of the BlockNote blocks OpenProject documents consist of. Requires no authentication. |
| `GET /api/v1/documents/content`   | Returns `{ revision, blocks }` with the current content of the document.                          |
| `PUT /api/v1/documents/content`   | Takes `{ revision, blocks }` and replaces the content of the document with the given blocks.      |

A `PUT` validates the blocks against the schema (`422` otherwise) and applies only the difference to the current
content as Yjs operations. The `revision` names the content the edit was based on. If the document changed since,
the edit is merged with those changes on block level. Changes to the same block, or changes to the order or nesting
of blocks on both sides, are rejected with `409`; the client then needs to read the document again.
Read revisions are remembered in memory for an hour.

### Starting the Server

```bash
# Development Mode (with hot reload):
npm run dev

# Production Mode
npm run start

# Debug Mode (with Node.js inspector):
npm run debug

# Run tests
npm run test

# Lint code
npm run lint
```

## Links

- [OpenProject](https://www.openproject.org/)
- [Hocuspocus Documentation](https://tiptap.dev/docs/hocuspocus/introduction)
- [Yjs Documentation](https://docs.yjs.dev/)
- [BlockNote Editor](https://www.blocknotejs.org/)
- [Repository Issues](https://github.com/opf/openproject/issues)

---

**Maintained by the OpenProject team**
