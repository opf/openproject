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

import { isTextEditable } from 'core-common/interactive-element-helper';

// Firefox does not let the mouse select text in a field that has a
// draggable ancestor, even when the drag itself is refused.
// https://community.openproject.org/wp/OP-20124
// https://bugzilla.mozilla.org/show_bug.cgi?id=1853069
export function suspendDraggableWhileEditing(element:HTMLElement):() => void {
  const listeners = new AbortController();
  const { signal } = listeners;
  const setDraggable = (draggable:boolean) => element.setAttribute('draggable', String(draggable));

  const { activeElement } = element.ownerDocument;
  if (element.contains(activeElement) && isTextEditable(activeElement)) {
    setDraggable(false);
  }

  element.addEventListener('focusin', (event) => {
    if (isTextEditable(event.target)) {
      setDraggable(false);
    }
  }, { signal });

  element.addEventListener('focusout', (event) => {
    const next = event.relatedTarget;
    const staysInTextField = next instanceof Node && element.contains(next) && isTextEditable(next);
    if (!staysInTextField) {
      setDraggable(true);
    }
  }, { signal });

  element.addEventListener('pointerdown', (event) => {
    setDraggable(!isTextEditable(event.target));
  }, { signal, capture: true });

  return () => listeners.abort();
}
