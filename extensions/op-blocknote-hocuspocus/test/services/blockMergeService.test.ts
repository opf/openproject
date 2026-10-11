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
import { mergeBlocks, type MergeableBlock } from "../../src/services/blockMergeService";

function block(id: string, text: string, children: MergeableBlock[] = []): MergeableBlock {
  return { id, type: "paragraph", content: text, children };
}

const base = [block("a", "A"), block("b", "B", [block("b1", "B1")]), block("c", "C")];

describe("mergeBlocks", () => {
  it("takes the submitted blocks when nobody else changed anything", () => {
    const mine = [block("a", "A!"), block("c", "C")];

    expect(mergeBlocks(base, mine, base)).toEqual({ merged: mine });
  });

  it("keeps concurrent edits to other blocks", () => {
    const mine = [block("a", "A by AI"), base[1], base[2]];
    const theirs = [base[0], block("b", "B by user", [block("b1", "B1")]), base[2]];

    expect(mergeBlocks(base, mine, theirs)).toEqual({
      merged: [block("a", "A by AI"), block("b", "B by user", [block("b1", "B1")]), base[2]],
    });
  });

  it("keeps concurrent edits when the submitter restructured the document", () => {
    const mine = [block("new", "Inserted"), base[0], base[1]];
    const theirs = [base[0], block("b", "B", [block("b1", "B1 by user")]), base[2]];

    expect(mergeBlocks(base, mine, theirs)).toEqual({
      merged: [block("new", "Inserted"), base[0], block("b", "B", [block("b1", "B1 by user")])],
    });
  });

  it("applies the submitter's content edits onto a concurrently restructured document", () => {
    const mine = [block("a", "A by AI"), base[1], base[2]];
    const theirs = [base[2], base[0]];

    expect(mergeBlocks(base, mine, theirs)).toEqual({
      merged: [base[2], block("a", "A by AI")],
    });
  });

  it("reports blocks edited on both sides", () => {
    const mine = [block("a", "A by AI"), base[1], base[2]];
    const theirs = [block("a", "A by user"), base[1], base[2]];

    expect(mergeBlocks(base, mine, theirs)).toEqual({ conflict: { reason: "content", blockIds: ["a"] } });
  });

  it("reports blocks deleted on one side and edited on the other", () => {
    const mine = [base[1], base[2]];
    const theirs = [block("a", "A by user"), base[1], base[2]];

    expect(mergeBlocks(base, mine, theirs)).toEqual({ conflict: { reason: "content", blockIds: ["a"] } });
  });

  it("reports structural changes on both sides", () => {
    const mine = [block("x", "X"), ...base];
    const theirs = [...base, block("y", "Y")];

    expect(mergeBlocks(base, mine, theirs)).toEqual({ conflict: { reason: "structure" } });
  });

  it("accepts identical changes on both sides", () => {
    const changed = [block("a", "Same"), base[2]];

    expect(mergeBlocks(base, changed, changed)).toEqual({ merged: changed });
  });
});
