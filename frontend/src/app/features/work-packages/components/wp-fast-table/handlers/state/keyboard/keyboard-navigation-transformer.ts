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
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { filter } from 'rxjs/operators';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { displayClassName, editableClassName } from 'core-app/shared/components/fields/display/display-field-renderer';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import type { WorkPackageTable } from '../../../wp-fast-table';
import type { TableEventComponent } from '../../table-handler-registry';
import { activateTableField } from '../../cell/edit-cell-handler';
import { activateRow } from '../../row/click-handler';
import {
  FocusPosition, initialPosition, NavigableRow, NavKey, nextPosition,
} from './focus-position';
import {
  buildNavigableRows, headerRowKey, headerRowOf, rowKindOf, totalsRowKey, totalsRowOf,
} from './navigable-rows';
import { navigableCellClassName, navigableCells, paintRovingTabindex } from './roving-tabindex';

export interface KeyboardNavigation {
  readonly position:FocusPosition|null;
  /** Makes the position the table's Tab stop, focuses it and scrolls it into view. */
  focusPosition(position:FocusPosition):void;
  /** Remembers the position without painting or focusing it. */
  recordPosition(position:FocusPosition):void;
  /** Focuses the origin again when its element still exists. */
  returnFocus(origin:FocusPosition):void;
  /** The row or cell element at the position, or null when it is not rendered. */
  elementAt(position:FocusPosition):HTMLElement|null;
  /** Handles Enter on a body cell; true when it acted. */
  onCellEnter:(position:FocusPosition) => boolean;
}

const plainKeys:Record<string, NavKey> = {
  ArrowUp: 'ArrowUp',
  ArrowDown: 'ArrowDown',
  ArrowLeft: 'ArrowLeft',
  ArrowRight: 'ArrowRight',
  Home: 'Home',
  End: 'End',
  PageUp: 'PageUp',
  PageDown: 'PageDown',
};

const commandKeys:Record<string, NavKey> = {
  Home: 'CtrlHome',
  End: 'CtrlEnd',
};

/** Moves focus across the rows and cells of a table with the keyboard, behind `keyboardNavigationEnabled`. */
export class KeyboardNavigationTransformer implements KeyboardNavigation {
  @LazyInject() public querySpace:IsolatedQuerySpace;

  @LazyInject() public wpTableHierarchies:WorkPackageViewHierarchiesService;

  @LazyInject() public collapsedGroups:WorkPackageViewCollapsedGroupsService;

  private current:FocusPosition|null = null;

  public onCellEnter = (position:FocusPosition):boolean => {
    const field = this.elementAt(position)?.querySelector<HTMLElement>(`.${displayClassName}.${editableClassName}`);
    return !!field && activateTableField(this.table, field);
  };

  constructor(
    public readonly injector:Injector,
    private readonly table:WorkPackageTable,
    private readonly view:TableEventComponent|null = null,
  ) {
    if (!table.configuration.keyboardNavigationEnabled) {
      return;
    }

    const { destroyRef, scrollContainer } = table;
    table.keyboardNavigation = this;
    const removedFromTabOrder = [scrollContainer, table.tableAndTimelineContainer]
      .filter((container, index, containers) => containers.indexOf(container) === index && !container.hasAttribute('tabindex'));
    removedFromTabOrder.forEach((container) => container.setAttribute('tabindex', '-1'));
    onDestroySafely(destroyRef, () => {
      removedFromTabOrder.forEach((container) => container.removeAttribute('tabindex'));
      if (table.keyboardNavigation === this) {
        table.keyboardNavigation = null;
      }
    });

    const onKeydown = (event:KeyboardEvent) => this.handleKeydown(event);
    const onFocusin = (event:FocusEvent) => this.adoptFocus(event.target as HTMLElement);
    scrollContainer.addEventListener('keydown', onKeydown);
    scrollContainer.addEventListener('focusin', onFocusin);
    onDestroySafely(destroyRef, () => {
      scrollContainer.removeEventListener('keydown', onKeydown);
      scrollContainer.removeEventListener('focusin', onFocusin);
    });

    this.querySpace.tableRendered.values$()
      .pipe(
        filter(() => table.ledger.generation > 0),
        takeUntilDestroyed(destroyRef),
      )
      .subscribe(() => this.paintAfterRender());
  }

  public get position():FocusPosition|null {
    return this.current;
  }

  public focusPosition(position:FocusPosition):void {
    const element = this.elementAt(position);
    if (!element) {
      return;
    }

    this.current = position;
    paintRovingTabindex(this.table.scrollContainer, element);
    element.focus({ preventScroll: true });
    this.scrollIntoView(element);
  }

  public recordPosition(position:FocusPosition):void {
    this.current = position;
  }

  public returnFocus(origin:FocusPosition):void {
    this.focusPosition(origin);
  }

  public elementAt(position:FocusPosition):HTMLElement|null {
    const row = this.rowElement(position.key);
    if (!row || position.cell === null) {
      return row;
    }

    return navigableCells(row)[position.cell] ?? null;
  }

  private rowElement(key:string):HTMLTableRowElement|null {
    switch (key) {
      case headerRowKey:
        return headerRowOf(this.table);
      case totalsRowKey:
        return totalsRowOf(this.table);
      default:
        return this.table.ledger.byKey(key)?.element ?? null;
    }
  }

  private paintAfterRender():void {
    const kept = this.current && this.elementAt(this.current);
    if (kept) {
      paintRovingTabindex(this.table.scrollContainer, kept);
      return;
    }

    this.current = null;
    const initial = initialPosition(buildNavigableRows(this.table));
    paintRovingTabindex(this.table.scrollContainer, initial && this.elementAt(initial));
  }

  private adoptFocus(target:HTMLElement):void {
    if (this.current && this.elementAt(this.current) === target) {
      return;
    }

    const position = this.positionOf(target);
    if (position) {
      this.current = position;
      paintRovingTabindex(this.table.scrollContainer, target);
    }
  }

  private positionOf(target:HTMLElement):FocusPosition|null {
    const isCell = target.classList.contains(navigableCellClassName);
    const row = isCell ? target.closest('tr') : target;
    if (!(row instanceof HTMLTableRowElement)) {
      return null;
    }

    const occurrence = this.table.ledger.byElement(row);
    const key = this.edgeKeyOf(row) ?? occurrence?.key;
    if (key === undefined) {
      return null;
    }

    const cell = isCell ? navigableCells(row).indexOf(target as HTMLTableCellElement) : null;
    const position:FocusPosition = { key, cell, desiredColumn: cell };
    const groupIdentifier = occurrence?.groupIdentifier;
    return groupIdentifier === undefined ? position : { ...position, groupIdentifier };
  }

  private edgeKeyOf(row:HTMLTableRowElement):string|undefined {
    if (row === headerRowOf(this.table)) {
      return headerRowKey;
    }

    return row === totalsRowOf(this.table) ? totalsRowKey : undefined;
  }

  private handleKeydown(event:KeyboardEvent):void {
    const position = this.current;
    if (position && event.key === 'Tab' && event.target === this.elementAt(position)) {
      paintRovingTabindex(this.table.scrollContainer, event.target as HTMLElement);
      return;
    }

    if (!position || this.ignored(event) || event.target !== this.elementAt(position)) {
      return;
    }

    const handled = event.key === 'Enter'
      ? this.activate(position)
      : this.navigate(position, event);

    if (handled) {
      event.preventDefault();
    }
  }

  private ignored(event:KeyboardEvent):boolean {
    const command = event.ctrlKey || event.metaKey;
    return event.isComposing
      || event.altKey
      || event.shiftKey
      || event.getModifierState('AltGraph')
      || (command && !(event.key in commandKeys));
  }

  private navigate(position:FocusPosition, event:KeyboardEvent):boolean {
    const key = (event.ctrlKey || event.metaKey ? commandKeys : plainKeys)[event.key];
    if (!key) {
      return false;
    }

    const rows = buildNavigableRows(this.table);
    const result = nextPosition(rows, position, key, this.pageSize(rows));
    switch (result.type) {
      case 'move':
        this.focusPosition(result.position);
        return true;
      case 'expand':
      case 'collapse':
        this.toggle(rows.find((row) => row.key === result.key)!);
        this.focusPosition(position);
        return true;
      default:
        return true;
    }
  }

  private toggle(row:NavigableRow):void {
    if (row.kind === 'groupHeader') {
      this.collapsedGroups.toggleGroupCollapseState(row.groupIdentifier ?? '');
      return;
    }

    const workPackageId = this.table.ledger.byKey(row.key)?.workPackageId;
    if (workPackageId) {
      this.wpTableHierarchies.toggle(workPackageId);
    }
  }

  private activate(position:FocusPosition):boolean {
    if (position.cell !== null) {
      return position.key === headerRowKey
        ? this.clickHeaderControl(this.elementAt(position))
        : this.onCellEnter(position);
    }

    const occurrence = this.table.ledger.byKey(position.key);
    if (!occurrence) {
      return false;
    }

    switch (rowKindOf(occurrence)) {
      case 'groupHeader':
        this.collapsedGroups.toggleGroupCollapseState(occurrence.groupIdentifier ?? '');
        this.focusPosition(position);
        return true;
      case 'workPackage':
        return this.activateWorkPackageRow(occurrence.workPackageId!, occurrence.element);
      default:
        return false;
    }
  }

  private activateWorkPackageRow(workPackageId:string, element:HTMLTableRowElement|null):boolean {
    if (!element || !this.view) {
      return false;
    }

    activateRow(this.view, workPackageId, element);
    return true;
  }

  private clickHeaderControl(cell:HTMLElement|null):boolean {
    const control = cell?.querySelector<HTMLElement>('a[href]')
      ?? cell?.querySelector<HTMLElement>('button.wp-table--columns-selection');
    control?.click();
    return !!control;
  }

  private pageSize(rows:NavigableRow[]):number {
    const first = rows.find((row) => !row.hidden && row.kind === 'workPackage');
    const rowHeight = first ? this.rowElement(first.key)?.getBoundingClientRect().height ?? 0 : 0;
    return rowHeight > 0 ? Math.max(1, Math.floor(this.table.scrollContainer.clientHeight / rowHeight)) : 1;
  }

  private scrollIntoView(element:HTMLElement):void {
    if (this.table.tbody.contains(element)) {
      element.style.scrollMarginTop = `${headerRowOf(this.table)?.getBoundingClientRect().height ?? 0}px`;
    }
    element.scrollIntoView({ block: 'nearest', inline: 'nearest' });
  }
}
