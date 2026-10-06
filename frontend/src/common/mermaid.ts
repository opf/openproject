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

import type { SvgToolbelt, ZoomFeature } from 'svg-toolbelt';

export const MERMAID_SELECTOR = 'pre[lang="mermaid"], code.language-mermaid';

const zoomables = new WeakMap<HTMLElement, SvgToolbelt>();

export function mermaidDiagramNodes(element:HTMLElement):HTMLElement[] {
  const nodes = new Set<HTMLElement>();

  element
    .querySelectorAll<HTMLElement>(MERMAID_SELECTOR)
    .forEach((node) => nodes.add(node.closest('pre') ?? node));

  return Array.from(nodes);
}

// Pan listens on `document`, so an instance outlives the node it was built on.
export function destroyMermaidDiagrams(element:HTMLElement):void {
  mermaidDiagramNodes(element).forEach((node) => {
    zoomables.get(node)?.destroy();
    zoomables.delete(node);
  });
}

function makeZoomable(node:HTMLElement, Toolbelt:typeof SvgToolbelt):void {
  const zoomable = new Toolbelt(node);
  zoomable.init();

  // Wheel zoom swallows page scroll over a diagram. ZoomFeature#destroy only
  // detaches that listener, so the controls and keyboard keep zooming.
  (zoomable.features.zoom as ZoomFeature).destroy();

  zoomables.set(node, zoomable);
}

async function render(nodes:HTMLElement[]):Promise<void> {
  const [{ default: mermaid }, { SvgToolbelt: Toolbelt }] = await Promise.all([
    import('mermaid'),
    import('svg-toolbelt'),
  ]);

  mermaid.initialize({
    securityLevel: 'strict',
    startOnLoad: false,
  });

  try {
    await mermaid.run({ nodes });
  } catch (error) {
    console.error(error);
  }

  nodes.forEach((node) => {
    // Mermaid marks a node `data-processed` before it awaits the render, so it
    // cannot be used to tell a painted diagram from a pending one.
    const painted = node.querySelector('svg') !== null;

    node.dataset.mermaidState = painted ? 'rendered' : 'failed';

    if (painted) {
      makeZoomable(node, Toolbelt);
    }
  });
}

export function renderMermaidDiagrams(element:HTMLElement):void {
  const nodes = mermaidDiagramNodes(element);

  if (nodes.length === 0) {
    return;
  }

  void render(nodes);
}
