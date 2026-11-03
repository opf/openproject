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
import { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import { activeFieldContainerClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageTableContextMenu } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-table-context-menu.directive';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { selectionGesture } from '../state/selection-feedback';
import { PositionArgs } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-view-context-menu.directive';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';

/**
 * Shift+F10 and the Menu key open the row menu on keydown, and the browser then fires its own `contextmenu` for the
 * same key press, possibly only on key release. That event is absorbed when it arrives within this many milliseconds;
 * it bounds browser event timing and has nothing to do with any CSS transition.
 */
const menuKeyCompanionWindowMs = 500;

const keyboardOpens = new WeakMap<WorkPackageTable, { row:HTMLElement, at:number }>();
const forgetOnTeardown = new WeakSet<WorkPackageTable>();

export function forgetKeyboardMenuOpen(table:WorkPackageTable):void {
  keyboardOpens.delete(table);
}

export abstract class ContextMenuHandler implements TableEventHandler {
  // Injections
  @LazyInject() public opContextMenu:OPContextMenuService;

  @LazyInject() readonly selectionGestures:WorkPackageViewSelectionGesturesService;

  constructor(public readonly injector:Injector) {
  }

  public get rowSelector() {
    return `.${tableRowClassName}`;
  }

  public abstract get EVENT():EventType|EventType[];

  public abstract get SELECTOR():string;

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tableAndTimelineContainer;
  }

  public abstract handleEvent(view:TableEventComponent, evt:Event):boolean;

  protected isUnsavedRow(row:HTMLElement|null):boolean {
    return row?.dataset.workPackageId === HAL_NEW_RESOURCE_ID;
  }

  protected isEditing(target:HTMLElement):boolean {
    return !!target.closest(`input, textarea, select, [contenteditable]:not([contenteditable="false"]), .${activeFieldContainerClassName}`);
  }

  protected noteKeyboardOpen(table:WorkPackageTable, row:HTMLElement):void {
    if (!forgetOnTeardown.has(table)) {
      forgetOnTeardown.add(table);
      onDestroySafely(table.destroyRef, () => keyboardOpens.delete(table));
    }
    keyboardOpens.set(table, { row, at: performance.now() });
  }

  protected refreshKeyboardOpen(table:WorkPackageTable, row:HTMLElement):void {
    const open = keyboardOpens.get(table);
    if (open?.row === row) {
      open.at = performance.now();
    }
  }

  protected forgetKeyboardOpen(table:WorkPackageTable):void {
    forgetKeyboardMenuOpen(table);
  }

  /** True once for the first `contextmenu` on `target` within the window after a keyboard open of its row; clears the record. */
  protected consumeCompanion(table:WorkPackageTable, target:HTMLElement):boolean {
    const open = keyboardOpens.get(table);
    keyboardOpens.delete(table);

    return !!open && performance.now() - open.at <= menuKeyCompanionWindowMs && open.row.contains(target);
  }

  protected openContextMenu(table:WorkPackageTable, evt:Event, row:HTMLElement, positionArgs:PositionArgs = {}):void {
    const workPackageId = row.dataset.workPackageId!;
    selectionGesture(table, 'navigation', () => {
      this.selectionGestures.handleContextMenu(workPackageId, table.renderedRows, row.dataset.classIdentifier);
    });

    const handler = new WorkPackageTableContextMenu(this.injector, workPackageId, evt.target as HTMLElement, positionArgs, table);
    this.opContextMenu.show(handler, evt);
  }
}
