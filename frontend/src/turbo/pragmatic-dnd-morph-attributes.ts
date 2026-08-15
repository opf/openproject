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

import { sortableListsRootSelector } from '../stimulus/controllers/dynamic/sortable-lists/list-dom';
import { batchSelectedAttribute } from '../stimulus/controllers/dynamic/sortable-lists/selection';

// `data-dragging` is shared with the legacy generic-drag-and-drop controller,
// so preservation is scoped to elements inside a sortable-lists root.
//
// Pragmatic's internal drop-target marker (`data-drop-target-for-element`) is
// deliberately NOT preserved: the sortable-lists root re-registers all
// children after a morph, which restores the marker together with the
// registry entry it stands for. Preserving only the marker would let it
// outlive the registration, and Pragmatic silently aborts its drop-target
// search at such an element.
const preservedAttributes = new Set([
  'data-dragging',
  // Drop indicator markers rendered by the sortable-lists item/list
  // controllers; a list refresh morphing mid-drag must not strip the
  // landing cue while the drag is still active.
  'data-drop-position',
  'data-drop-position-owner',
  'data-drop-container',
  // Batch membership, owned by the sortable-lists root. The root reconciles it
  // after every morph batch anyway, but preserving it avoids a visible flash
  // between the morph and that reconciliation.
  batchSelectedAttribute,
  // Current-work-package marker set by the backlogs work-package controller,
  // which only re-syncs it on `turbo:visit`; a morph would otherwise strip
  // the highlight of the open work package.
  'aria-current',
]);

let registered = false;

export function registerPragmaticDndMorphAttributePreservation():void {
  if (registered) {
    return;
  }

  registered = true;
  document.addEventListener('turbo:before-morph-attribute', (event) => {
    if (!preservedAttributes.has(event.detail.attributeName)) {
      return;
    }

    // Only protect removals: these markers are Pragmatic DnD-owned and absent
    // from server HTML, so a morph strips them. A server-driven add/update of
    // the same attribute should still be allowed through.
    if (event.detail.mutationType !== 'remove') {
      return;
    }

    if (!(event.target instanceof Element) || event.target.closest(sortableListsRootSelector) === null) {
      return;
    }

    event.preventDefault();
  });
}
