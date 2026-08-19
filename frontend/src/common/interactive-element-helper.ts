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

const ariaInteractiveRoles = new Set([
  'button',
  'checkbox',
  'combobox',
  'link',
  'listbox',
  'menuitem',
  'menuitemcheckbox',
  'menuitemradio',
  'option',
  'radio',
  'slider',
  'spinbutton',
  'switch',
  'tab',
  'textbox',
  'treeitem',
]);

export function isInteractiveElement(el:Element|null):el is HTMLElement {
  if (!(el instanceof HTMLElement)) return false;
  if (el.hasAttribute('disabled')) return false;
  if (el.getAttribute('aria-disabled') === 'true') return false;
  if (el.hidden) return false;

  const tag = el.tagName.toLowerCase();
  const role = el.getAttribute('role');
  const tabIndex = el.tabIndex;

  const nativeInteractive = tag === 'button'
    || tag === 'select'
    || tag === 'textarea'
    || tag === 'summary'
    || (tag === 'input' && (el as HTMLInputElement).type !== 'hidden')
    || (tag === 'a' && el.hasAttribute('href'))
    || (tag === 'audio' && el.hasAttribute('controls'))
    || (tag === 'video' && el.hasAttribute('controls'));

  return nativeInteractive
    || (role != null && ariaInteractiveRoles.has(role))
    || el.isContentEditable
    || tabIndex >= 0;
}

export function closestInteractiveElement(el:Element|null, stopAt:Element|null = null):HTMLElement|null {
  let current = el;

  while (current && current !== stopAt) {
    if (isInteractiveElement(current)) {
      return current;
    }

    current = current.parentElement;
  }

  return null;
}

// Drag-start gating variant: an interactive ancestor blocks a drag from
// starting on it, UNLESS it opts back in via `data-draggable-surface` — for
// an activation surface that doubles as the drag surface, e.g. a card made
// keyboard-activatable with role="button"/tabindex spanning the entire
// draggable item. Buttons and links nested inside such a surface still block.
export function closestDragBlockingElement(el:Element|null, stopAt:Element|null = null):HTMLElement|null {
  let current = el;

  while (current && current !== stopAt) {
    if (isInteractiveElement(current) && !current.hasAttribute('data-draggable-surface')) {
      return current;
    }

    current = current.parentElement;
  }

  return null;
}
