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

import mermaid from 'mermaid';

export const MERMAID_SELECTOR = 'pre[lang="mermaid"], code.language-mermaid';

export function mermaidDiagramNodes(element:HTMLElement):HTMLElement[] {
  const nodes = new Set<HTMLElement>();

  element
    .querySelectorAll<HTMLElement>(MERMAID_SELECTOR)
    .forEach((node) => nodes.add(node.closest('pre') ?? node));

  return Array.from(nodes);
}

// Mermaid marks a node `data-processed` before it awaits the render, so it
// cannot be used to tell a painted diagram from a pending one.
function markRendered(node:HTMLElement):void {
  node.dataset.mermaidState = node.querySelector('svg') ? 'rendered' : 'failed';
}

export function renderMermaidDiagrams(element:HTMLElement):void {
  const nodes = mermaidDiagramNodes(element);

  if (nodes.length === 0) {
    return;
  }

  mermaid.initialize({
    securityLevel: 'strict',
    startOnLoad: false,
  });

  void mermaid
    .run({ nodes })
    .catch(console.error)
    .finally(() => nodes.forEach(markRendered));
}
