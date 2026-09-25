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

const selectionEscapes = new WeakSet<Event>();

const openOverlaySelector = [
  'dialog[open]',
  ':popover-open',
  '.op-context-menu--overlay [role="menu"]',
  '.spot-modal-overlay_active',
  '.spot-drop-modal_opened',
].join(',');

const escapeOwnerSelector = [
  '[role="dialog"]',
  '[role="menu"]',
  '[role="listbox"]',
  'input',
  'textarea',
  'select',
  '[contenteditable]',
].join(',');

/**
 * Clears a selection root on an unowned Escape.
 *
 * @remarks
 * Every root listens at the document in the bubble phase. An Escape a
 * dismissable overlay or an editable control owns is left alone; one that
 * another root's selection consumed still clears this root. The consumer
 * owns state and any announcement.
 */
export function clearSelectionOnEscape(
  event:KeyboardEvent,
  hasState:() => boolean,
  clear:() => void,
):void {
  if (event.key !== 'Escape' || (event.defaultPrevented && !selectionEscapes.has(event))) return;
  const target = event.target;
  const ownerDocument = target instanceof Node ? target.ownerDocument ?? document : document;
  if (ownerDocument.querySelector(openOverlaySelector)) return;
  if (target instanceof Element && target.closest(escapeOwnerSelector)) return;
  if (!hasState()) return;
  event.preventDefault();
  selectionEscapes.add(event);
  clear();
}
