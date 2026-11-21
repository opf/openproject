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

import { Injectable, inject } from '@angular/core';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import Mousetrap from 'mousetrap';

// this could be extracted into a separate component if it grows
const accessibleListSelector = 'table.keyboard-accessible-list';

@Injectable({
  providedIn: 'root',
})
export class KeyboardShortcutService {
  private readonly configurationService = inject(ConfigurationService);

  // maybe move it to a .constant
  private shortcuts:Record<string, () => void> = {
    'k': () => this.focusPrevItem(),
    'j': () => this.focusNextItem(),
  };

  /**
   * Register the keyboard shortcuts.
   */
  public register():void {
    void this.configurationService.initialize().then(() => {
      if (!this.configurationService.disableKeyboardShortcuts()) {
        Object.entries(this.shortcuts).forEach(([key, action]) => Mousetrap.bind(key, action));
      }
    });
  }

  focusItemOffset(offset:number):void {
    const active = document.activeElement;
    const enclosing = active?.closest(accessibleListSelector) ?? null;
    const list = enclosing ?? this.nearestList(active, offset);
    if (!list) {
      return;
    }

    const rows = Array.from(list.querySelectorAll<HTMLTableRowElement>('tbody.work-package--results-tbody > tr, tbody > tr.wp-table--sums-row'))
      .filter((row) => row.checkVisibility());
    const current = enclosing ? active?.closest('tr') ?? null : null;
    const index = current ? rows.indexOf(current) : -1;
    const start = !enclosing && offset < 0 ? rows.length : index;
    for (let next = start + offset; next >= 0 && next < rows.length; next += offset) {
      if (!rows[next].classList.contains('wp-table--sums-row')) {
        rows[next].focus();
        return;
      }
    }
  }

  private nearestList(active:Element|null, offset:number):Element|null {
    const lists = Array.from(document.querySelectorAll(accessibleListSelector)).filter((list) => list.checkVisibility());
    const side = offset > 0 ? Node.DOCUMENT_POSITION_FOLLOWING : Node.DOCUMENT_POSITION_PRECEDING;
    const onSide = active ? lists.filter((list) => (active.compareDocumentPosition(list) & side) !== 0) : [];

    return offset > 0
      ? onSide[0] ?? lists[0] ?? null
      : onSide.at(-1) ?? lists.at(-1) ?? null;
  }

  focusNextItem():void {
    this.focusItemOffset(1);
  }

  focusPrevItem():void {
    this.focusItemOffset(-1);
  }
}
