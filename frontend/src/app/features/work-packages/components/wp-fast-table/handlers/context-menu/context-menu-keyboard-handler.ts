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

import { Injector } from '@angular/core';
import { TableEventComponent } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { uiStateLinkClass } from '../../builders/ui-state-link-builder';
import { keyboardNavigationEnabled } from '../state/keyboard/roving-tabindex';
import { ContextMenuHandler } from './context-menu-handler';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class ContextMenuKeyboardHandler extends ContextMenuHandler {
  constructor(public readonly injector:Injector) {
    super(injector);
  }

  public get EVENT():EventType {
    return 'keydown';
  }

  public get SELECTOR() {
    return this.rowSelector;
  }

  public handleEvent(component:TableEventComponent, evt:KeyboardEvent):boolean {
    const { configuration } = component.workPackageTable;
    if (!configuration.contextMenuEnabled) {
      return false;
    }

    const target = evt.target as HTMLElement;
    const keyboardNavigation = keyboardNavigationEnabled(configuration);

    if (!this.isMenuChord(evt, keyboardNavigation)
      || (keyboardNavigation && (this.isEditing(target) || target.closest(`.${uiStateLinkClass}`)))) {
      return true;
    }

    const row = target.closest<HTMLTableRowElement>(this.SELECTOR);

    if (!row?.dataset.workPackageId || this.isUnsavedRow(row)) {
      return true;
    }

    evt.preventDefault();
    evt.stopPropagation();

    if (evt.repeat) {
      this.refreshKeyboardOpen(component.workPackageTable, row);
      return false;
    }

    super.openContextMenu(
      component.workPackageTable,
      evt,
      row,
      // Set position args to open at element
      { placement: 'bottom-start', reference: target }
    );
    this.noteKeyboardOpen(component.workPackageTable, row);

    return false;
  }

  private isMenuChord(evt:KeyboardEvent, keyboardNavigation:boolean):boolean {
    if (!keyboardNavigation) {
      return evt.key === 'F10' && evt.shiftKey && evt.altKey;
    }

    if (evt.key === 'ContextMenu') {
      return true;
    }

    return evt.key === 'F10' && evt.shiftKey && !evt.ctrlKey && !evt.metaKey;
  }
}
