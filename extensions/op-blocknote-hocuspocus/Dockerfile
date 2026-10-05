# syntax=docker/dockerfile:1
ARG NODE_VERSION=24

# Production dependencies only; cached until package manifests change.
FROM node:${NODE_VERSION}-trixie-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm ci --omit=dev

# local: same runtime as production but with a shell for debugging.
FROM node:${NODE_VERSION}-trixie-slim AS local
ENV NODE_ENV=development
WORKDIR /app
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json package-lock.json ./
COPY --chown=node:node src ./src
USER node
EXPOSE 1234
CMD ["node_modules/tsx/dist/cli.mjs", "src/index.ts", "--no-daemon"]

# staging and production: distroless, no shell, non-root.
FROM gcr.io/distroless/nodejs${NODE_VERSION}-debian13:nonroot AS production
ARG VERSION=unknown
ARG REVISION=unknown
LABEL org.opencontainers.image.title="OpenProject Hocuspocus" \
      org.opencontainers.image.source="https://github.com/opf/openproject" \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.revision=$REVISION
ENV NODE_ENV=production
WORKDIR /app
COPY --from=deps --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --chown=nonroot:nonroot package.json package-lock.json ./
COPY --chown=nonroot:nonroot src ./src
EXPOSE 1234
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/nodejs/bin/node", "-e", "require('net').connect(1234,'127.0.0.1').on('connect',()=>process.exit(0)).on('error',()=>process.exit(1))"]
CMD ["node_modules/tsx/dist/cli.mjs", "src/index.ts", "--no-daemon"]

FROM production AS staging
