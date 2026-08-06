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

import { debugLog } from '../debug_output';

/**
 * Try to set the position on the given input element.
 *
 * @param element The element to set the cursor to
 * @param offset The character offset retrieved from getPosition.
 */
export function setPosition(element:HTMLInputElement, offset:number):void {
  try {
    element.setSelectionRange(offset, offset);
  } catch (e) {
    debugLog('Failed to set click position for edit field.', e);
  }
}

/**
 * Get the cursor offset from the click event.
 *
 * @param evt
 * @return {number}
 */
export function getPosition(evt:MouseEvent):number {
  try {
    if ((evt as any).rangeParent) {
      const range = document.createRange();
      range.setStart((evt as any).rangeParent, (evt as any).rangeOffset);
      return range.startOffset;
    }

    const legacyDocument = document as { caretRangeFromPoint?:(x:number, y:number) => { startOffset:number } };
    if (legacyDocument.caretRangeFromPoint) {
      return legacyDocument
        .caretRangeFromPoint(evt.clientX, evt.clientY)
        .startOffset;
    }

    return 0;
  } catch (e) {
    debugLog('Failed to get click position for edit field.', e);
    return 0;
  }
}
