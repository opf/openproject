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

import { createBlockSpec, createInlineContentSpec, plainContentToString } from "@blocknote/core";

// `@blocknote/math-block` cannot run in Node (it imports KaTeX's CSS, and its React rendering crashes
// the process after an export), so these mirror its specs. Type, content and `code` must stay in sync
// with the editor, or Yjs content does not map onto this schema. The markdown exporter reads the LaTeX
// from the `application/x-tex` annotation.
function mathElement(latex:string, display:"block" | "inline") {
  const namespace = "http://www.w3.org/1998/Math/MathML";
  const math = document.createElementNS(namespace, "math");
  const semantics = document.createElementNS(namespace, "semantics");
  const annotation = document.createElementNS(namespace, "annotation");

  math.setAttribute("display", display);
  annotation.setAttribute("encoding", "application/x-tex");
  annotation.textContent = latex;
  semantics.append(annotation);
  math.append(semantics);

  return math as unknown as HTMLElement;
}

export const mathBlockStaticSpec = createBlockSpec(
  { type: "mathBlock", propSchema: {}, content: "plain" },
  {
    meta: { code: true, defining: true, isolating: false },
    render: (block) => ({ dom: mathElement(plainContentToString(block.content), "block") }),
  },
);

export const mathInlineStaticSpec = createInlineContentSpec(
  { type: "math", propSchema: {}, content: "plain" },
  {
    meta: { code: true },
    render: (inlineContent) => ({ dom: mathElement(plainContentToString(inlineContent.content), "inline") }),
  },
);
