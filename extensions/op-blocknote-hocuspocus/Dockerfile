FROM node:24-trixie-slim AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY src/ ./src

FROM gcr.io/distroless/nodejs24-debian13:nonroot

ENV NODE_ENV=production
WORKDIR /app

COPY --from=build --chown=nonroot:nonroot /app/package*.json ./
COPY --from=build --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --from=build --chown=nonroot:nonroot /app/src ./src

EXPOSE 1234

CMD ["node_modules/tsx/dist/cli.mjs", "src/index.ts", "--no-daemon"]
