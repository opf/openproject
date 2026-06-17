import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { Server } from "@hocuspocus/server";
import { HocuspocusProvider } from "@hocuspocus/provider";
import { HocuspocusProvider as HocuspocusProviderPrev } from "@hocuspocus/provider-prev-test-only";
import * as Y from "yjs";
import { ws } from "msw";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { OpenProjectApi } from "../../src/extensions/openProjectApi";
import { createTestToken } from "../helpers/tokenHelper";
import { server as apiMock } from "../mocks/node";

// Proves a real @hocuspocus/provider completes the connect -> authenticate -> load -> sync
// handshake against our server over the actual wire protocol. The server boots in-process so
// the existing msw mocks intercept its outbound Rails calls.
const PORT = 9678;
// Must equal the token's resource_url: onAuthenticate sets resourceUrl = documentName
// and validates they match. createTestToken() defaults to this URL.
const DOC_NAME = "https://test.api/api/v3/documents/1";

// setup.ts runs msw with onUnhandledRequest:'error', which also patches the global
// WebSocket. Passthrough the connection to the in-process server so the real client
// transport is exercised; Rails calls to test.api stay mocked by the default handlers.
const socketLink = ws.link(`ws://127.0.0.1:${PORT}`);

// Expected provider majors, declared statically so a version bump forces a conscious edit
// here as well as in package.json (the previous major is a manual `npm:` alias that won't
// move on its own). The guard test below cross-checks these against the installed versions
// and enforces the one-major gap Hocuspocus supports.
const CURRENT_MAJOR = 4;
const PREVIOUS_MAJOR = 3;

// The installed manifest is the source of truth — package.json's `^3` range only states
// intent, not what npm resolved. Read the file directly rather than require()-ing it: these
// packages' `exports` maps don't expose ./package.json, so require('<pkg>/package.json')
// throws ERR_PACKAGE_PATH_NOT_EXPORTED. Path is anchored to this file so cwd doesn't matter.
const packageRoot = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const installedMajor = (pkg: string): number => {
  const { version } = JSON.parse(
    readFileSync(join(packageRoot, "node_modules", pkg, "package.json"), "utf8"),
  ) as { version: string };
  return Number(version.split(".")[0]);
};

// The two provider majors have incompatible constructor/config types, so the matrix drives
// both through this minimal duck-typed shape (hence the `as unknown as` casts below). If a
// future major renames `synced`/`destroy` or changes the config, update this shape — TS can't
// see through the cast, so the only symptom would be the sync poll silently timing out.
interface ProviderConfig {
  url: string;
  name: string;
  token: string;
  document: Y.Doc;
}
interface ProviderInstance {
  synced: boolean;
  destroy(): void;
}
type ProviderConstructor = new (config: ProviderConfig) => ProviderInstance;

const providers = [
  { label: `v${CURRENT_MAJOR} (current)`, pkg: "@hocuspocus/provider", major: CURRENT_MAJOR, Provider: HocuspocusProvider as unknown as ProviderConstructor },
  { label: `v${PREVIOUS_MAJOR} (previous)`, pkg: "@hocuspocus/provider-prev-test-only", major: PREVIOUS_MAJOR, Provider: HocuspocusProviderPrev as unknown as ProviderConstructor },
] as const;

let hocuspocus: Server;

beforeAll(async () => {
  hocuspocus = new Server({ port: PORT, quiet: true, extensions: [new OpenProjectApi()] });
  await hocuspocus.listen();
});

afterAll(async () => {
  await hocuspocus?.destroy();
});

beforeEach(() => {
  apiMock.use(socketLink.addEventListener("connection", ({ server }) => server.connect()));
});

it("provider matrix stays within Hocuspocus's one-major skew window", () => {
  for (const { pkg, major } of providers) {
    expect(
      installedMajor(pkg),
      `${pkg} resolved to a different major than declared — update CURRENT_MAJOR/PREVIOUS_MAJOR and package.json together`,
    ).toBe(major);
  }
  expect(
    CURRENT_MAJOR - PREVIOUS_MAJOR,
    "the matrix must stay exactly one major apart; bump the @hocuspocus/provider-prev-test-only alias in package.json",
  ).toBe(1);
});

describe.each(providers)("@hocuspocus/provider ($label) <-> server", ({ Provider }) => {
  it("connects, authenticates, and syncs", async () => {
    const provider = new Provider({
      url: `ws://127.0.0.1:${PORT}`,
      name: DOC_NAME,
      token: createTestToken(),
      document: new Y.Doc(),
    });

    // finally so a failed/timed-out poll still tears down the socket and reconnect timers,
    // which would otherwise leak handles and hang the run.
    try {
      await expect.poll(() => provider.synced, { timeout: 10000 }).toBe(true);
    } finally {
      provider.destroy();
    }
  });
});
