//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { HocuspocusProvider } from "@hocuspocus/provider";
import { Server } from "@hocuspocus/server";
import { http, HttpResponse, ws } from "msw";
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "vitest";
import * as Y from "yjs";
import { OpenProjectApi } from "../../src/extensions/openProjectApi";
import { createTestToken } from "../helpers/tokenHelper";
import { server as apiMock } from "../mocks/node";

const PORT = 9679;
const WHITEBOARD_URL = "https://test.api/api/v3/whiteboards/7";
const socketLink = ws.link(`ws://127.0.0.1:${PORT}`);

function storedWhiteboard() {
  const doc = new Y.Doc();
  doc.getMap("elements").set("seed", { id: "seed", type: "text", index: "a0", version: 1, text: "Seed" });
  return Buffer.from(Y.encodeStateAsUpdate(doc)).toString("base64");
}

function connect(readonly = false) {
  return new HocuspocusProvider({
    url: `ws://127.0.0.1:${PORT}`,
    name: WHITEBOARD_URL,
    token: createTestToken({ resource_url: WHITEBOARD_URL, readonly }),
    document: new Y.Doc(),
  });
}

let hocuspocus: Server;
let storedBodies: Record<string, unknown>[];
let providers: HocuspocusProvider[];

beforeAll(async () => {
  hocuspocus = new Server({ port: PORT, quiet: true, debounce: 50, extensions: [new OpenProjectApi()] });
  await hocuspocus.listen();
});

afterAll(async () => {
  await hocuspocus?.destroy();
});

beforeEach(() => {
  storedBodies = [];
  providers = [];
  apiMock.use(
    socketLink.addEventListener("connection", ({ server }) => server.connect()),
    http.get(WHITEBOARD_URL, () => HttpResponse.json({
      _type: "Whiteboard",
      _links: { self: { href: "/api/v3/whiteboards/7" }, update: { href: "/api/v3/whiteboards/7" } },
      contentBinary: storedWhiteboard(),
    })),
    http.patch(WHITEBOARD_URL, async ({ request }) => {
      storedBodies.push(await request.json() as Record<string, unknown>);
      return HttpResponse.json({});
    }),
  );
});

afterEach(() => {
  providers.forEach((provider) => provider.destroy());
});

describe("whiteboard collaboration through Hocuspocus", () => {
  it("loads the stored scene, syncs drawings between clients and stores the scene projection", async () => {
    const alice = connect();
    const bob = connect();
    providers.push(alice, bob);
    const bobNotifications: string[] = [];
    bob.on("stateless", ({ payload }: { payload: string }) => bobNotifications.push(payload));
    await expect.poll(() => alice.synced && bob.synced, { timeout: 10000 }).toBe(true);

    expect(bob.document.getMap("elements").has("seed")).toBe(true);

    alice.document.getMap("elements").set("r1", { id: "r1", type: "rectangle", index: "a1", version: 1 });
    await expect.poll(() => bob.document.getMap("elements").has("r1"), { timeout: 5000 }).toBe(true);

    await expect.poll(() => storedBodies.at(-1), { timeout: 5000 }).toMatchObject({
      scene: { elements: [{ id: "seed" }, { id: "r1" }] },
      searchable_text: "Seed",
    });
    expect(storedBodies.at(-1)).toHaveProperty("content_binary");
    expect(storedBodies.at(-1)).not.toHaveProperty("description");
    await expect.poll(() => bobNotifications, { timeout: 5000 }).toContain("storeEvent");
  });

  it("shares presence through awareness", async () => {
    const alice = connect();
    const bob = connect();
    providers.push(alice, bob);
    await expect.poll(() => alice.synced && bob.synced, { timeout: 10000 }).toBe(true);

    alice.awareness!.setLocalStateField("user", { id: 1, name: "Alice" });
    alice.awareness!.setLocalStateField("pointer", { x: 10, y: 20, tool: "pointer" });

    await expect.poll(() => {
      const states = Array.from(bob.awareness!.getStates().values()) as { user?: { name: string }, pointer?: unknown }[];
      return states.find((state) => state.user?.name === "Alice")?.pointer;
    }, { timeout: 5000 }).toEqual({ x: 10, y: 20, tool: "pointer" });
  });

  it("does not let read-only clients change the whiteboard", async () => {
    apiMock.use(http.get(WHITEBOARD_URL, () => HttpResponse.json({
      _type: "Whiteboard",
      _links: { self: { href: "/api/v3/whiteboards/7" } },
      contentBinary: storedWhiteboard(),
    })));

    const viewer = connect(true);
    providers.push(viewer);
    await expect.poll(() => viewer.synced, { timeout: 10000 }).toBe(true);

    viewer.document.getMap("elements").set("vandalism", { id: "vandalism", type: "rectangle", version: 1 });
    await new Promise((resolve) => setTimeout(resolve, 300));

    expect(storedBodies).toHaveLength(0);
    const serverDoc = hocuspocus.hocuspocus.documents.get(WHITEBOARD_URL);
    expect(serverDoc?.getMap("elements").has("vandalism")).toBe(false);
  });
});
