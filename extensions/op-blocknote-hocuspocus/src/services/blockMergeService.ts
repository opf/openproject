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

import { isDeepStrictEqual } from "node:util";

export interface MergeableBlock {
  id: string;
  children: MergeableBlock[];
  [key: string]: unknown;
}

type BlockContent = Omit<MergeableBlock, "children">;

export type MergeConflict =
  { reason: "content", blockIds: string[] } | { reason: "structure" };

export type MergeResult<B extends MergeableBlock> =
  { merged: B[] } | { conflict: MergeConflict };

function flatten(blocks: MergeableBlock[], into = new Map<string, BlockContent>()) {
  for (const { children, ...content } of blocks) {
    into.set(content.id, content);
    flatten(children, into);
  }
  return into;
}

function structure(blocks: MergeableBlock[]): unknown[] {
  return blocks.map(({ id, children }) => [id, structure(children)]);
}

function mergeContent(base?: BlockContent, mine?: BlockContent, theirs?: BlockContent): { content?: BlockContent } | "conflict" {
  if (isDeepStrictEqual(mine, theirs)) return { content: mine };
  if (isDeepStrictEqual(mine, base)) return { content: theirs };
  if (isDeepStrictEqual(theirs, base)) return { content: mine };
  return "conflict";
}

function rebuild<B extends MergeableBlock>(shape: MergeableBlock[], contents: Map<string, BlockContent>): B[] {
  return shape.map(({ id, children }) => ({
    ...contents.get(id),
    children: rebuild(children, contents),
  }) as B);
}

/**
 * Three-way merge of BlockNote block trees on block granularity.
 *
 * `mine` carries the changes of the submitter, made on top of `base`.
 * `theirs` is the live state, which may have moved on since `base` was read.
 * A block's own content (everything except its children) merges cleanly if only one side changed it.
 * The tree structure (order, nesting, insertions, deletions) merges cleanly if only one side changed it.
 */
export function mergeBlocks<B extends MergeableBlock>(base: B[], mine: B[], theirs: B[]): MergeResult<B> {
  const flatBase = flatten(base);
  const flatMine = flatten(mine);
  const flatTheirs = flatten(theirs);

  const conflictingBlockIds: string[] = [];
  const contents = new Map<string, BlockContent>();
  const ids = new Set([...flatBase.keys(), ...flatMine.keys(), ...flatTheirs.keys()]);

  for (const id of ids) {
    const result = mergeContent(flatBase.get(id), flatMine.get(id), flatTheirs.get(id));
    if (result === "conflict") {
      conflictingBlockIds.push(id);
    } else if (result.content) {
      contents.set(id, result.content);
    }
  }

  const baseStructure = structure(base);
  const mineStructure = structure(mine);
  const theirsStructure = structure(theirs);

  let shape: MergeableBlock[];
  if (isDeepStrictEqual(theirsStructure, baseStructure) || isDeepStrictEqual(theirsStructure, mineStructure)) {
    shape = mine;
  } else if (isDeepStrictEqual(mineStructure, baseStructure)) {
    shape = theirs;
  } else {
    return { conflict: { reason: "structure" } };
  }

  if (conflictingBlockIds.length > 0) {
    return { conflict: { reason: "content", blockIds: conflictingBlockIds } };
  }

  return { merged: rebuild<B>(shape, contents) };
}
