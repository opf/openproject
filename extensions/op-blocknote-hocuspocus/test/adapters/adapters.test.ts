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

import { describe, expect, test } from "vitest";
import * as Y from "yjs";
import { adapterFor } from "../../src/adapters";
import { blockNoteDocumentAdapter } from "../../src/adapters/blockNoteDocumentAdapter";
import { excalidrawWhiteboardAdapter } from "../../src/adapters/excalidrawWhiteboardAdapter";

describe("adapterFor", () => {
  test("picks the BlockNote adapter for documents", () => {
    expect(adapterFor("https://op.test/api/v3/documents/1")).toBe(blockNoteDocumentAdapter);
  });

  test("picks the Excalidraw adapter for whiteboards", () => {
    expect(adapterFor("https://op.test/subdir/api/v3/whiteboards/7")).toBe(excalidrawWhiteboardAdapter);
  });

  test("rejects unknown resources", () => {
    expect(() => adapterFor("https://op.test/api/v3/work_packages/1"))
      .toThrowError("No content adapter for resource https://op.test/api/v3/work_packages/1");
  });
});

describe("excalidrawWhiteboardAdapter", () => {
  function whiteboardDoc() {
    const doc = new Y.Doc();
    const elements = doc.getMap("elements");
    elements.set("b", { id: "b", type: "text", index: "a1", text: "second" });
    elements.set("a", { id: "a", type: "text", index: "a0", text: "first" });
    elements.set("c", { id: "c", type: "rectangle", index: "a2" });
    elements.set("gone", { id: "gone", type: "text", index: "a3", text: "deleted", isDeleted: true });
    doc.getMap("files").set("f1", { mimeType: "image/png", attachmentId: 3 });
    return doc;
  }

  test("projects live elements in fractional index order", async () => {
    const { scene } = await excalidrawWhiteboardAdapter.storeAttributes(whiteboardDoc()) as {
      scene: { elements: { id: string }[], files: Record<string, unknown> }
    };

    expect(scene.elements.map((element) => element.id)).toEqual(["a", "b", "c"]);
    expect(scene.files).toEqual({ f1: { mimeType: "image/png", attachmentId: 3 } });
  });

  test("collects text of live text elements for search", async () => {
    const attributes = await excalidrawWhiteboardAdapter.storeAttributes(whiteboardDoc());

    expect(attributes.searchable_text).toEqual("first\nsecond");
  });
});
