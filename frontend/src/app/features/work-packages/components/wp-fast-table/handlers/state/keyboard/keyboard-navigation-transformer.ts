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
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { displayClassName, editableClassName } from 'core-app/shared/components/fields/display/display-field-renderer';
import { activeFieldContainerClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { isApplePlatform } from 'core-common/platform';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import type { WorkPackageTable } from '../../../wp-fast-table';
import { wpOccurrenceKey } from '../../../rendered-occurrence-ledger';
import type { TableEventComponent } from '../../table-handler-registry';
import { activateTableField } from '../../cell/edit-cell-handler';
import { activateRow } from '../../row/click-handler';
import { rowKindOf } from '../../../helpers/row-expansion';
import {
  FocusPosition, initialPosition, NavigableRow, NavKey, nearestPosition, computeNextPosition, reconcilePosition,
} from './focus-position';
import {
  buildNavigableRows, headerRowKey, headerRowOf, totalsRowKey, totalsRowOf,
} from './navigable-rows';
import { selectableOccurrences } from 'core-app/features/work-packages/routing/wp-view-base/view-services/rendered-occurrences';
import { KeyboardSelection, selectionChord } from './keyboard-selection';
import { insideGrid, navigableCellClassName, navigableCells, paintRovingTabindex } from './roving-tabindex';

export interface KeyboardNavigation {
  readonly position:FocusPosition|null;
  /** Makes the position the table's Tab stop, focuses it and scrolls it into view. */
  focusPosition(position:FocusPosition):void;
  /** Remembers the position without painting or focusing it. */
  recordPosition(position:FocusPosition):void;
  /** Focuses the origin again, or the row hiding it, unless the user has since moved elsewhere, an editor is open or focus rests on a live control; true when it focused. */
  returnFocus(origin:FocusPosition):boolean;
  /** Returns focus to `origin` after a menu closed, though focus visited the menu portal; same userPosition guard as returnFocus, and never takes focus from a control outside the table. */
  returnFocusFromMenu(origin:FocusPosition):void;
  /** The position of the navigable cell or row enclosing `cell`, or null when it is not a rendered occurrence. */
  positionOfCell(cell:HTMLElement):FocusPosition|null;
  /** The row or cell element at the position, or null when it is not rendered. */
  elementAt(position:FocusPosition):HTMLElement|null;
  /** Handles Enter on a body cell; true when it acted. */
  onCellEnter:(position:FocusPosition) => boolean;
  /** Records whether focus is inside the table before a mutation replaces or hides its rows. */
  captureOwnership():void;
}

interface RenderedRows {
  rows:NavigableRow[];
  groupBy:string|null;
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

const pointerEndEvents = ['mouseup', 'click', 'pointerup', 'pointercancel', 'dragend'] as const;

/** Moves focus across the rows and cells of a table with the keyboard, behind `keyboardNavigationEnabled`. */
export class KeyboardNavigationTransformer implements KeyboardNavigation {
  @LazyInject() public querySpace:IsolatedQuerySpace;

  @LazyInject() public wpTableHierarchies:WorkPackageViewHierarchiesService;

  @LazyInject() public collapsedGroups:WorkPackageViewCollapsedGroupsService;

  @LazyInject() public wpTableFocus:WorkPackageViewFocusService;

  @LazyInject() public wpTableSelection:WorkPackageViewSelectionService;

  private current:FocusPosition|null = null;

  private userPosition:FocusPosition|null = null;

  private owned = false;

  private focusLeftTable = false;

  private capturing = false;

  private pointerActive = false;

  private rendered:RenderedRows = { rows: [], groupBy: null };

  private selecting!:KeyboardSelection;

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
    this.selecting = new KeyboardSelection(table, this.wpTableSelection);
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
    const onFocusin = (event:FocusEvent) => {
      this.focusLeftTable = !insideGrid(scrollContainer, event.target as Node);
      const from = event.relatedTarget;
      this.adoptFocus(event.target as HTMLElement, !insideGrid(scrollContainer, from as Node|null));
    };
    const onFocusout = (event:FocusEvent) => {
      const next = event.relatedTarget ?? event.target;
      this.focusLeftTable = !insideGrid(scrollContainer, next as Node);
    };
    scrollContainer.addEventListener('keydown', onKeydown);
    const onMousedown = (event:MouseEvent) => {
      this.pointerActive = true;
      this.recordPointerTarget(event.target);
    };
    const onPointerEnd = () => { this.pointerActive = false; };
    scrollContainer.addEventListener('focusin', onFocusin);
    scrollContainer.addEventListener('focusout', onFocusout);
    scrollContainer.addEventListener('mousedown', onMousedown);
    pointerEndEvents.forEach((type) => document.addEventListener(type, onPointerEnd));
    onDestroySafely(destroyRef, () => {
      scrollContainer.removeEventListener('keydown', onKeydown);
      scrollContainer.removeEventListener('focusin', onFocusin);
      scrollContainer.removeEventListener('focusout', onFocusout);
      scrollContainer.removeEventListener('mousedown', onMousedown);
      pointerEndEvents.forEach((type) => document.removeEventListener(type, onPointerEnd));
    });

    this.querySpace.tableRendered.values$()
      .pipe(
        filter(() => table.ledger.generation > 0),
        takeUntilDestroyed(destroyRef),
      )
      .subscribe(() => this.recover(this.requestedPosition()));

    table.rowsRefreshed$
      .pipe(takeUntilDestroyed(destroyRef))
      .subscribe(() => this.recover(null));
  }

  public get position():FocusPosition|null {
    return this.current;
  }

  public focusPosition(position:FocusPosition):void {
    const element = this.moveFocusTo(position);
    if (element) {
      this.scrollIntoView(element);
    }
  }

  public recordPosition(position:FocusPosition):void {
    this.current = position;
    this.userPosition = position;
  }

  public captureOwnership():void {
    const inside = insideGrid(this.table.scrollContainer, document.activeElement);
    if (this.capturing || this.table.hasPendingRender) {
      this.owned ||= inside;
    } else {
      this.owned = inside;
    }

    if (!this.capturing) {
      this.capturing = true;
      queueMicrotask(() => { this.capturing = false; });
    }
  }

  public returnFocusFromMenu(origin:FocusPosition):void {
    if (this.table.destroyed || !this.focusAtRest()) {
      return;
    }

    const focusLeftTable = this.focusLeftTable;
    this.focusLeftTable = false;
    if (this.returnFocus(origin)) {
      this.owned = true;
    } else {
      this.focusLeftTable = focusLeftTable;
    }
  }

  public returnFocus(origin:FocusPosition):boolean {
    const user = this.userPosition;
    if (user && (user.key !== origin.key || user.cell !== origin.cell)) {
      return false;
    }

    const rows = buildNavigableRows(this.table);
    const originIndex = rows.findIndex((row) => row.key === origin.key);
    const target = originIndex === -1 ? this.current : reconcilePosition(rows, origin, originIndex);
    if (!target || !this.mayRestoreFocus()) {
      return false;
    }

    this.focusPosition(target);
    return true;
  }

  public positionOfCell(cell:Element):FocusPosition|null {
    return this.positionOf(cell.closest<HTMLElement>(`.${navigableCellClassName}`) ?? cell.closest('tr'));
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

  private requestedPosition():FocusPosition|null {
    let requested:FocusPosition|null = null;
    this.wpTableFocus.ifShouldFocus((workPackageId) => {
      requested = { key: wpOccurrenceKey(workPackageId), cell: null, desiredColumn: null };
    });
    return requested;
  }

  private recover(requested:FocusPosition|null):void {
    if (this.table.destroyed) {
      return;
    }

    const owned = this.owned;
    if (!this.table.hasPendingRender) {
      this.owned = false;
    }
    const previous = this.rendered;
    const rows = buildNavigableRows(this.table);
    this.rendered = { rows, groupBy: this.groupBy() };

    if (requested && this.elementAt(requested)) {
      this.userPosition = requested;
      this.focusPosition(requested);
      return;
    }

    this.current = this.current && this.reconcile(rows, previous, this.current);
    if (this.current && owned && this.mayRestoreFocus()) {
      this.focusPosition(this.current);
      return;
    }

    const painted = this.current ?? initialPosition(rows);
    paintRovingTabindex(this.table.scrollContainer, painted && this.elementAt(painted));
  }

  private reconcile(rows:NavigableRow[], previous:RenderedRows, position:FocusPosition):FocusPosition|null {
    if (!rows.some((row) => row.kind !== 'header' && row.kind !== 'totals')) {
      const header = rows.find((row) => row.kind === 'header');
      return header ? { key: header.key, cell: null, desiredColumn: null } : null;
    }

    const previousIndex = previous.rows.findIndex((row) => row.key === position.key);
    const regrouped = position.groupIdentifier !== undefined && previous.groupBy !== this.rendered.groupBy;
    return regrouped ? nearestPosition(rows, previousIndex) : reconcilePosition(rows, position, previousIndex);
  }

  private mayRestoreFocus():boolean {
    const editing = Object.values(this.table.editing.forms).some((form) => form.hasActiveFields());
    return !editing && !this.focusLeftTable && this.focusAtRest();
  }

  private focusAtRest():boolean {
    const active = document.activeElement;
    return !active
      || active === document.body
      || !active.isConnected
      || (insideGrid(this.table.scrollContainer, active) && this.hiddenOrUnlisted(active));
  }

  private hiddenOrUnlisted(element:Element):boolean {
    const row = element.closest('tr');
    if (!row) {
      return true;
    }

    if (this.edgeKeyOf(row) !== undefined) {
      return false;
    }

    return this.table.ledger.byElement(row)?.hidden ?? true;
  }

  private groupBy():string|null {
    return this.querySpace.query.value?.groupBy?.id ?? null;
  }

  private adoptFocus(target:HTMLElement, fromOutside:boolean):void {
    if (this.current && this.elementAt(this.current) === target) {
      return;
    }

    const position = this.positionOf(target);
    if (position) {
      this.current = position;
      paintRovingTabindex(this.table.scrollContainer, target);
      return;
    }

    const enclosing = this.pointerActive || !fromOutside ? null : this.enclosingPositionOf(target);
    if (enclosing) {
      this.moveFocusTo(enclosing);
    }
  }

  private moveFocusTo(position:FocusPosition):HTMLElement|null {
    const element = this.elementAt(position);
    if (!element) {
      return null;
    }

    this.current = position;
    paintRovingTabindex(this.table.scrollContainer, element);
    element.focus({ preventScroll: true });
    return element;
  }

  private enclosingPositionOf(innerControl:HTMLElement):FocusPosition|null {
    if (innerControl.getAttribute('tabindex') !== '-1' || innerControl.closest(`.${activeFieldContainerClassName}`)) {
      return null;
    }

    return this.positionOfCell(innerControl);
  }

  private recordPointerTarget(target:EventTarget|null):void {
    if (!(target instanceof Element)) {
      return;
    }

    const position = this.positionOfCell(target);
    if (position) {
      this.current = position;
      this.userPosition = position;
      paintRovingTabindex(this.table.scrollContainer, this.elementAt(position));
    }
  }

  private positionOf(target:HTMLElement|null):FocusPosition|null {
    if (!target) {
      return null;
    }

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

    if (!position || event.target !== this.elementAt(position)) {
      return;
    }

    if (this.handleSelectionChord(position, event) || this.ignored(event)) {
      return;
    }

    const handled = event.key === 'Enter'
      ? this.activate(position)
      : this.navigate(position, event);

    if (handled) {
      event.preventDefault();
    }
  }

  private handleSelectionChord(position:FocusPosition, event:KeyboardEvent):boolean {
    const chord = selectionChord(event, isApplePlatform());
    switch (chord) {
      case null:
        return false;
      case 'toggle':
        if (this.selecting.occurrenceAt(position)) {
          event.preventDefault();
          if (!event.repeat) {
            this.selecting.toggle(position);
          }
        }
        return true;
      case 'selectAll':
        if (selectableOccurrences(this.table.renderedRows).length > 0) {
          event.preventDefault();
          if (!event.repeat) {
            this.selecting.selectAll(position);
          }
        }
        return true;
      default:
        event.preventDefault();
        this.extendSelection(position, event);
        return true;
    }
  }

  private extendSelection(position:FocusPosition, event:KeyboardEvent):void {
    this.navigate(position, event);
    const arrived = this.current;
    if (arrived && (arrived.key !== position.key || arrived.cell !== position.cell)) {
      this.selecting.extendTo(arrived);
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
    const result = computeNextPosition(rows, position, key, this.pageSize(rows));
    switch (result.type) {
      case 'move':
        this.userPosition = result.position;
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
    const control = cell?.querySelector<HTMLElement>('a')
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
