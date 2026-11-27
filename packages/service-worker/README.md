# Service worker

The OpenProject service worker: offline page, push notifications and the app icon badge for the installed web app.

## Overview

This is a standalone npm package, written in TypeScript. It is not part of the frontend build in `frontend/` and shares no dependencies with it.

```
src/main.ts                               entry point
        |
        |  npm run build (esbuild)
        v
app/views/pwa/_service_worker_bundle.js   build output, committed
        |
        |  printed inline by app/views/pwa/service-worker.js.erb
        v
GET /service-worker                       the script the browser registers
```

The build output is a single script and is committed to the repository, so the production build does not run npm or esbuild for the worker.

Values that depend on the instance, such as URLs and translated titles, are not known at build time. The view prints them as `self.OP_SW` in front of the bundle; `src/config.ts` describes their shape.

## Getting started

Use the Node.js and npm versions from `engines` in `package.json`, and run all commands in this folder.

1. Install the dependencies:

   ```shell
   npm ci
   ```

2. Change the source in `src/`, starting from `src/main.ts`. To rebuild on every change while you work:

   ```shell
   npm run build:watch
   ```

3. Check your work:

   ```shell
   npm test
   npm run typecheck
   npm run lint
   ```

4. Build, and commit the regenerated bundle together with your change:

   ```shell
   npm run build
   ```

   Do not edit `app/views/pwa/_service_worker_bundle.js` by hand. CI rebuilds it and fails when the committed file differs.

### With the Docker development setup

The `frontend` container has the right Node.js and npm versions and mounts the whole repository, so the same commands run there. From the repository root, with the container running:

```shell
docker compose exec -w /home/dev/openproject/packages/service-worker frontend npm ci
docker compose exec -w /home/dev/openproject/packages/service-worker frontend npm test
docker compose exec -w /home/dev/openproject/packages/service-worker frontend npm run build
```

`bin/compose setup` does not install the dependencies of this package; run `npm ci` as shown above once before the other commands.
