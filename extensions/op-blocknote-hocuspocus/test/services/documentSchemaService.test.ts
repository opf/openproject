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

import { describe, expect, it } from "vitest";
import { createEditor } from "../../src/editor";
import { validateBlocks } from "../../src/services/documentSchemaService";

describe("validateBlocks", () => {
  it("accepts the blocks BlockNote itself produces", () => {
    const editor = createEditor();
    const blocks = editor._prosemirrorNodeToBlocks(editor._blocksToProsemirrorNode([
      { type: "heading", props: { level: 2 }, content: "Title" },
      { type: "paragraph", content: [{ type: "text", text: "bold", styles: { bold: true } }, { type: "link", href: "https://example.com", content: "link" }] },
      { type: "bulletListItem", content: "item", children: [{ type: "checkListItem", props: { checked: true }, content: "nested" }] },
      { type: "codeBlock", props: { language: "ruby" }, content: "puts 1" },
      { type: "table", content: { type: "tableContent", rows: [{ cells: ["a", "b"] }] } },
      { type: "openProjectWorkPackageBlock", props: { wpid: 42 } },
      { type: "paragraph", content: [{ type: "openProjectWorkPackageInline", props: { wpid: "42", size: "s", displayId: "" } }] },
      { type: "divider" },
    ]));

    expect(validateBlocks(JSON.parse(JSON.stringify(blocks)))).toEqual({ valid: true });
  });

  it("accepts partial blocks with string shorthand content", () => {
    expect(validateBlocks([{ type: "paragraph", content: "Hello" }])).toEqual({ valid: true });
  });

  it("rejects unknown block types", () => {
    const result = validateBlocks([{ type: "mermaid", content: "graph" }]);

    expect(result.valid).toBe(false);
    expect(result.valid || result.errors.join()).toContain("/0/type must be equal to one of the allowed values");
  });

  it("rejects prop values outside of the allowed set", () => {
    const result = validateBlocks([{ type: "heading", props: { level: 9 }, content: "Title" }]);

    expect(result.valid || result.errors.join()).toContain("/0/props/level must be equal to one of the allowed values (1, 2, 3, 4, 5, 6)");
  });

  it("rejects unknown props", () => {
    const result = validateBlocks([{ type: "paragraph", props: { fontSize: 12 } }]);

    expect(result.valid || result.errors.join()).toContain("/0/props must NOT have additional properties 'fontSize'");
  });

  it("rejects content on blocks without content", () => {
    const result = validateBlocks([{ type: "divider", content: "text" }]);

    expect(result.valid || result.errors.join()).toContain("/0/content");
  });

  it("validates nested children", () => {
    const result = validateBlocks([{ type: "paragraph", children: [{ type: "paragraph", content: [{ type: "text" }] }] }]);

    expect(result.valid || result.errors.join()).toContain("/0/children/0/content");
  });

  it("rejects a non-array document", () => {
    expect(validateBlocks({ type: "paragraph" }).valid).toBe(false);
  });
});
