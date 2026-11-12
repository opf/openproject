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

import { OpContextMenuCloseReason } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

/**
 * Hands focus back to `target` after a menu closed: always on Escape, and
 * after an action or a scroll only when nothing else holds focus.
 */
export function focusAfterMenuClose(target:HTMLElement, reason:OpContextMenuCloseReason|undefined):void {
  const { activeElement } = target.ownerDocument;
  const focusLost = activeElement === null || activeElement === target.ownerDocument.body;
  if (reason === 'escape' || ((reason === 'action' || reason === 'scroll') && focusLost)) {
    target.focus({ preventScroll: true });
  }
}
