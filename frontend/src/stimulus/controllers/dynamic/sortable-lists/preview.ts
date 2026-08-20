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

import { html, render } from 'lit-html';

// Builds the custom native drag preview for a sortable item: a sanitised clone
// of the item's preview target, sized to match and carrying the originating
// Box's density so its card styling survives being mounted outside the Box.

// Attributes stripped from the cloned drag preview so it carries no behaviour or
// stale interaction state. The dynamic `data-*--*-target` attributes are removed
// separately in sanitizePreview.
// `data-batch-selected` is deliberately absent: it lives on the sortable
// item element (the row, in Backlogs), while the preview target is the card
// — the row's child, never its clone. It can never end up on this clone, so
// stripping it here would be dead code.
const PREVIEW_STRIPPED_ATTRIBUTES = [
  'data-controller',
  'data-action',
  'data-dragging',
  'data-drop-position',
  'data-drop-position-owner',
  'aria-current',
  'aria-describedby',
  'aria-disabled',
  'aria-roledescription',
] as const;

// Box density variant classes copied onto the drag-preview container. The preview is
// mounted outside the originating Box, so variant-scoped card styles (e.g.
// `.Box--condensed .Box-card`) would not apply to it otherwise.
const BOX_DENSITY_VARIANT_CLASSES = ['Box--condensed', 'Box--spacious'] as const;

// The count badge on a multi-card drag's preview, styled on Primer's Counter
// contract plus this class for the positioning Counter does not own. The
// native drag snapshot is taken synchronously at dragstart, before an Angular
// element would have painted, so it cannot be a custom element.
const BATCH_BADGE_CLASS = 'op-sortable-lists-drag-preview-batch-badge';

// Ghost layers drawn behind the clone, one per further card in the batch, so
// the stack itself carries the magnitude the badge spells out. Past four cards
// the added depth stops reading, so the layers stop too.
const DRAG_STACK_MAX_LAYERS = 3;

// Reserved as container padding so nothing paints past the border box: Firefox
// folds such overflow into the drag snapshot and shifts its origin off the grab
// offset. Written inline because Pragmatic inline-resets the container before
// render(), and only a later inline write outranks that; the item controller
// reads the top padding back to compensate the grab offset. Reserved for the
// deepest stack whatever the batch size, so the badge keeps one offset.
// Mirrors `$op-drag-badge-overhang` and `$op-drag-stack-overhang` in
// drag_and_drop.sass.
const BATCH_BADGE_OVERHANG_PX = 8;
const DRAG_STACK_OVERHANG_PX = 22;

export function renderDragPreview({
  previewTarget,
  sourceElement,
  container,
  batchSize = 1,
}:{
  previewTarget:HTMLElement;
  sourceElement:HTMLElement;
  container:HTMLElement;
  // A batch larger than one card adds a count badge, so a multi-card drag
  // reads differently from a single one.
  batchSize?:number;
}):void {
  const previewWidth = previewTarget.getBoundingClientRect().width;
  const preview = previewTarget.cloneNode(true) as HTMLElement;

  sanitizePreview(preview);
  preview.setAttribute('data-preview', '');

  if (previewWidth > 0) {
    preview.style.width = `${previewWidth}px`;
  }

  // Margin utility classes on the source (e.g. mt-3 on a section box) would
  // render as whitespace inside the preview container.
  preview.style.margin = '0';

  const box = sourceElement.closest('.Box');

  BOX_DENSITY_VARIANT_CLASSES.forEach((variant) => {
    if (box?.classList.contains(variant)) {
      container.classList.add(variant);
    }
  });

  container.append(preview);

  if (batchSize > 1) {
    preview.setAttribute('data-stack-depth', `${Math.min(batchSize - 1, DRAG_STACK_MAX_LAYERS)}`);

    // Anchors the badge to the container rather than whatever ancestor
    // Pragmatic mounts it under. Nothing paints past the card's left edge.
    container.style.position = 'relative';
    container.style.paddingTop = `${BATCH_BADGE_OVERHANG_PX}px`;
    container.style.paddingRight = `${DRAG_STACK_OVERHANG_PX}px`;
    container.style.paddingBottom = `${DRAG_STACK_OVERHANG_PX}px`;
    renderBatchBadge(container, batchSize);
  }
}

// Absolutely positioned over the card clone's top-right corner; the
// container's padding is the overhang it sits in (drag_and_drop.sass).
//
// render() is safe on a container that already holds the preview clone: it
// inserts a marker before its own end node and manages content from there
// on, rather than clearing pre-existing children.
function renderBatchBadge(container:HTMLElement, batchSize:number):void {
  render(html`<span class="Counter Counter--primary ${BATCH_BADGE_CLASS}">${batchSize}</span>`, container);
}

export function sanitizePreview(element:HTMLElement):void {
  // Avoid side effects from custom elements (e.g. Primer include-fragment) in the cloned preview.
  element.querySelectorAll('include-fragment').forEach((fragment) => fragment.remove());

  const nodes = [element, ...Array.from(element.querySelectorAll<HTMLElement>('*'))];

  for (const node of nodes) {
    PREVIEW_STRIPPED_ATTRIBUTES.forEach((attribute) => node.removeAttribute(attribute));

    for (const attribute of Array.from(node.attributes)) {
      if (/^data-.+--.+-target$/.test(attribute.name)) {
        node.removeAttribute(attribute.name);
      }
    }
  }
}
