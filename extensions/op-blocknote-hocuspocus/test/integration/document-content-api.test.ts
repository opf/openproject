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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { Server } from "@hocuspocus/server";
import { HocuspocusProvider } from "@hocuspocus/provider";
import { http, HttpResponse, passthrough, ws } from "msw";
import * as Y from "yjs";
import { createEditor, DOCUMENT_FRAGMENT } from "../../src/editor";
import { CONTENT_PATH, DocumentContentApi, SCHEMA_PATH } from "../../src/extensions/documentContentApi";
import { OpenProjectApi } from "../../src/extensions/openProjectApi";
import { readBlocks } from "../../src/services/documentContentService";
import { createExpiredToken, createTestToken } from "../helpers/tokenHelper";
import { server as apiMock } from "../mocks/node";

const PORT = 9679;
const BASE_URL = `http://127.0.0.1:${PORT}`;
const socketLink = ws.link(`ws://127.0.0.1:${PORT}`);

let hocuspocus: Server;
let documentCount = 0;
let documentUrl: string;
let storedContent: string;
let editable: boolean;
let patches: { content_binary: string, description: string }[];

function encode(blocks: Parameters<ReturnType<typeof createEditor>["blocksToYDoc"]>[0]) {
  const doc = createEditor().blocksToYDoc(blocks, DOCUMENT_FRAGMENT);
  return Buffer.from(Y.encodeStateAsUpdate(doc)).toString("base64");
}

function token() {
  return createTestToken({ resource_url: documentUrl });
}

function connectEditor(document: Y.Doc) {
  return new HocuspocusProvider({ url: `ws://127.0.0.1:${PORT}`, name: documentUrl, token: token(), document });
}

function request(method: string, path: string, { token: authToken = token(), body }: { token?: string | null, body?: unknown } = {}) {
  return fetch(`${BASE_URL}${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(authToken && { Authorization: `Bearer ${authToken}` }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function readContent() {
  const response = await request("GET", CONTENT_PATH);
  expect(response.status).toBe(200);
  return await response.json() as { revision: string, blocks: { id: string, content: unknown }[] };
}

function text(value: string) {
  return [{ type: "text", text: value, styles: {} }];
}

beforeAll(async () => {
  hocuspocus = new Server({ port: PORT, quiet: true, extensions: [new OpenProjectApi(), new DocumentContentApi()] });
  await hocuspocus.listen();
});

afterAll(async () => {
  await hocuspocus?.destroy();
});

beforeEach(() => {
  documentUrl = `https://test.api/api/v3/documents/${++documentCount}`;
  editable = true;
  patches = [];
  storedContent = encode([
    { id: "intro", type: "paragraph", content: "Introduction" },
    { id: "body", type: "paragraph", content: "Body" },
  ]);

  apiMock.use(
    http.get(documentUrl, () => HttpResponse.json({
      id: String(documentCount),
      contentBinary: storedContent,
      _links: editable ? { update: { href: documentUrl, method: "patch" } } : {},
    })),
    http.patch(documentUrl, async ({ request }) => {
      const body = await request.json() as { content_binary: string, description: string };
      patches.push(body);
      storedContent = body.content_binary;
      return HttpResponse.json({ id: String(documentCount) });
    }),
    http.all(`${BASE_URL}/*`, () => passthrough()),
    socketLink.addEventListener("connection", ({ server }) => server.connect()),
  );
});

describe("GET schema", () => {
  it("returns the JSON schema of document content", async () => {
    const response = await request("GET", SCHEMA_PATH, { token: null });
    const schema = await response.json();

    expect(response.status).toBe(200);
    expect(schema.type).toBe("array");
    expect(schema.definitions.block.properties.type.enum).toContain("openProjectWorkPackageBlock");
  });
});

describe("routing", () => {
  it("serves requests forwarded with the path hocuspocus is mounted under", async () => {
    expect((await request("GET", `/hocuspocus${SCHEMA_PATH}`, { token: null })).status).toBe(200);
  });

  it("leaves other requests to hocuspocus", async () => {
    expect(await (await request("GET", "/", { token: null })).text()).toBe("Welcome to Hocuspocus!");
  });

  it("rejects unsupported methods", async () => {
    expect((await request("DELETE", CONTENT_PATH)).status).toBe(405);
  });
});

describe("GET content", () => {
  it("returns the stored blocks with a revision", async () => {
    const { revision, blocks } = await readContent();

    expect(revision).toEqual(expect.any(String));
    expect(blocks.map(({ id, content }) => [id, content])).toEqual([
      ["intro", text("Introduction")],
      ["body", text("Body")],
    ]);
  });

  it("rejects requests without a valid token", async () => {
    expect((await request("GET", CONTENT_PATH, { token: null })).status).toBe(401);
    expect((await request("GET", CONTENT_PATH, { token: "garbage" })).status).toBe(401);
    expect((await request("GET", CONTENT_PATH, { token: createExpiredToken({ resource_url: documentUrl }) })).status).toBe(401);
  });
});

describe("PUT content", () => {
  it("applies the edit, persists it and returns the new state", async () => {
    const { revision, blocks } = await readContent();
    blocks[1].content = text("Edited body");

    const response = await request("PUT", CONTENT_PATH, {
      body: { revision, blocks: [...blocks, { type: "heading", content: "Added" }] },
    });
    const result = await response.json();

    expect(response.status).toBe(200);
    expect(result.revision).not.toEqual(revision);
    expect(result.blocks.map(({ content }: { content: unknown }) => content)).toEqual([
      text("Introduction"), text("Edited body"), text("Added"),
    ]);
    expect(patches).toHaveLength(1);
    expect(patches[0].description).toContain("Edited body");
    expect((await readContent()).blocks).toEqual(result.blocks);
  });

  it("broadcasts the edit to connected editors", async () => {
    const editorDocument = new Y.Doc();
    const provider = connectEditor(editorDocument);

    try {
      await expect.poll(() => provider.synced, { timeout: 10000 }).toBe(true);

      const { revision, blocks } = await readContent();
      blocks[0].content = text("Written by the assistant");
      expect((await request("PUT", CONTENT_PATH, { body: { revision, blocks } })).status).toBe(200);

      await expect.poll(() => readBlocks(editorDocument)[0]?.content, { timeout: 5000 })
        .toEqual(text("Written by the assistant"));
    } finally {
      provider.destroy();
    }
  });

  it("merges with edits made by others since the content was read", async () => {
    const editorDocument = new Y.Doc();
    const provider = connectEditor(editorDocument);

    try {
      await expect.poll(() => provider.synced, { timeout: 10000 }).toBe(true);
      const { revision, blocks } = await readContent();

      const blockGroup = editorDocument.getXmlFragment(DOCUMENT_FRAGMENT).firstChild as Y.XmlElement;
      const bodyParagraph = (blockGroup.get(1) as Y.XmlElement).firstChild as Y.XmlElement;
      const bodyText = bodyParagraph.firstChild as Y.XmlText;
      bodyText.insert(4, " typed by a user");
      await expect.poll(async () => (await readContent()).blocks[1].content).toEqual(text("Body typed by a user"));

      blocks[0].content = text("Introduction by the assistant");
      const response = await request("PUT", CONTENT_PATH, { body: { revision, blocks } });

      expect(response.status).toBe(200);
      expect((await response.json()).blocks.map(({ content }: { content: unknown }) => content)).toEqual([
        text("Introduction by the assistant"), text("Body typed by a user"),
      ]);
    } finally {
      provider.destroy();
    }
  });

  it("merges concurrent typing in the same block", async () => {
    const editorDocument = new Y.Doc();
    const provider = connectEditor(editorDocument);

    try {
      await expect.poll(() => provider.synced, { timeout: 10000 }).toBe(true);
      const { revision, blocks } = await readContent();

      const blockGroup = editorDocument.getXmlFragment(DOCUMENT_FRAGMENT).firstChild as Y.XmlElement;
      const introParagraph = (blockGroup.get(0) as Y.XmlElement).firstChild as Y.XmlElement;
      (introParagraph.firstChild as Y.XmlText).insert(0, "Short ");
      await expect.poll(async () => (await readContent()).blocks[0].content).toEqual(text("Short Introduction"));

      blocks[0].content = text("Introduction, extended by the assistant");
      const response = await request("PUT", CONTENT_PATH, { body: { revision, blocks } });

      expect(response.status).toBe(200);
      expect((await response.json()).blocks[0].content).toEqual(text("Short Introduction, extended by the assistant"));
      await expect.poll(() => readBlocks(editorDocument)[0]?.content, { timeout: 5000 })
        .toEqual(text("Short Introduction, extended by the assistant"));
    } finally {
      provider.destroy();
    }
  });

  it("applies a repeated submission based on the same revision only once", async () => {
    const { revision, blocks } = await readContent();
    const body = { revision, blocks: [...blocks, { type: "paragraph", content: "Added once" }] };

    const first = await (await request("PUT", CONTENT_PATH, { body })).json();
    const added = first.blocks[2];
    body.blocks[2] = added;
    const second = await request("PUT", CONTENT_PATH, { body });

    expect(second.status).toBe(200);
    expect((await second.json()).blocks.map(({ id }: { id: string }) => id)).toEqual(["intro", "body", added.id]);
  });

  it("rejects edits based on an unknown revision", async () => {
    const response = await request("PUT", CONTENT_PATH, { body: { revision: "unknown", blocks: [{ type: "paragraph" }] } });

    expect(response.status).toBe(409);
    expect((await response.json()).error).toContain("Read the document again");
  });

  it("rejects blocks that do not match the schema", async () => {
    const { revision } = await readContent();
    const response = await request("PUT", CONTENT_PATH, { body: { revision, blocks: [{ type: "unknown" }] } });

    expect(response.status).toBe(422);
    expect((await response.json()).errors).toEqual(expect.arrayContaining([expect.stringContaining("/0/type")]));
    expect(patches).toHaveLength(0);
  });

  it("rejects duplicate block ids", async () => {
    const { revision, blocks } = await readContent();
    const response = await request("PUT", CONTENT_PATH, { body: { revision, blocks: [...blocks, blocks[0]] } });

    expect(response.status).toBe(422);
  });

  it("rejects edits from users without edit permission", async () => {
    editable = false;
    const { revision, blocks } = await readContent();
    const response = await request("PUT", CONTENT_PATH, { body: { revision, blocks } });

    expect(response.status).toBe(403);
  });
});
