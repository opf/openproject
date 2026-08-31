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

// Builds the custom native drag preview for a sortable item: a sanitised clone
// of the item's preview target, sized to match and carrying the originating
// Box's density so its card styling survives being mounted outside the Box.

// Attributes stripped from the cloned drag preview so it carries no behaviour or
// stale interaction state. The dynamic `data-*--*-target` attributes are removed
// separately in sanitizePreview.
const PREVIEW_STRIPPED_ATTRIBUTES = [
  'data-controller',
  'data-action',
  'data-dragging',
  'data-drop-position',
  'data-drop-position-owner',
  'data-selected',
  'aria-current',
  'aria-describedby',
  'aria-disabled',
  'aria-roledescription',
] as const;

// Box density variant classes copied onto the drag-preview container. The preview is
// mounted outside the originating Box, so variant-scoped card styles (e.g.
// `.Box--condensed .Box-card`) would not apply to it otherwise.
const BOX_DENSITY_VARIANT_CLASSES = ['Box--condensed', 'Box--spacious'] as const;

export function renderDragPreview({
  previewTarget,
  sourceElement,
  container,
}:{
  previewTarget:HTMLElement;
  sourceElement:HTMLElement;
  container:HTMLElement;
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
