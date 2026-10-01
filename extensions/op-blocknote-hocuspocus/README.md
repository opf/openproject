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
