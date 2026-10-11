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

import { createHash } from "node:crypto";
import { updateYFragment } from "y-prosemirror";
import * as Y from "yjs";
import { createEditor, DOCUMENT_FRAGMENT, type OpEditor } from "../editor";

export type DocumentBlock = ReturnType<OpEditor["yXmlFragmentToBlocks"]>[number];
type PartialDocumentBlock = Parameters<OpEditor["_blocksToProsemirrorNode"]>[0][number];

let sharedEditor: OpEditor | undefined;

function editor(): OpEditor {
  sharedEditor ??= createEditor();
  return sharedEditor;
}

export function readBlocks(doc: Y.Doc): DocumentBlock[] {
  return editor().yXmlFragmentToBlocks(doc.getXmlFragment(DOCUMENT_FRAGMENT));
}

export function revisionOf(blocks: DocumentBlock[]): string {
  return createHash("sha256").update(JSON.stringify(blocks)).digest("hex").slice(0, 32);
}

/**
 * Converts submitted (possibly partial) blocks into the canonical form BlockNote itself produces,
 * filling in default props and generating ids for new blocks. An empty document holds a single empty paragraph.
 * Throws if the blocks cannot be represented in the editor schema.
 */
export function normalizeBlocks(blocks: unknown[]): DocumentBlock[] {
  const nonEmpty = blocks.length > 0 ? blocks : [{ type: "paragraph" }];
  const node = editor()._blocksToProsemirrorNode(nonEmpty as PartialDocumentBlock[]);
  node.check();
  return editor()._prosemirrorNodeToBlocks(node) as DocumentBlock[];
}

export function duplicateBlockIds(blocks: unknown[]): string[] {
  const seen = new Set<string>();
  const duplicates = new Set<string>();

  const visit = (list: unknown[]) => {
    for (const block of list as { id?: string, children?: unknown[] }[]) {
      if (block.id) {
        if (seen.has(block.id)) duplicates.add(block.id);
        seen.add(block.id);
      }
      visit(block.children ?? []);
    }
  };
  visit(blocks);

  return [...duplicates];
}

/**
 * Applies the difference between the document's current content and the given blocks
 * as Yjs operations, the same way a local edit in a connected editor would.
 */
export function writeBlocks(doc: Y.Doc, blocks: DocumentBlock[]): void {
  const node = editor()._blocksToProsemirrorNode(blocks);
  const fragment = doc.getXmlFragment(DOCUMENT_FRAGMENT);

  updateYFragment(doc, fragment, node, { mapping: new Map(), isOMark: new Map() });
}
