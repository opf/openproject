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
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { activeFieldContainerClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { isApplePlatform } from 'core-common/platform';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import type { WorkPackageTable } from '../../../wp-fast-table';
import type { MutationExit, PaintScope } from '../../../row-mutations';
import { wpOccurrenceKey } from '../../../rendered-occurrence-ledger';
import type { TableEventComponent } from '../../table-handler-registry';
import { activateRow } from '../../row/click-handler';
import { rowKindOf } from '../../../helpers/row-expansion';
import type { RowRecord, RowRecordKind } from '../../../semantics/row-classifier';
import { headerRowKey, totalsRowKey } from '../../../row-keys';
import { headerRowOf, totalsRowOf } from '../../../helpers/structural-rows';
import {
  FocusPosition, initialPosition, NavigableRow, nearestPosition, computeNextPosition, reconcilePosition, ROW_KINDS, RowKind, rowPosition,
  samePosition,
} from './focus-position';
import { isSelectableOccurrence, selectableOccurrences } from 'core-app/features/work-packages/routing/wp-view-base/view-services/rendered-occurrences';
import { KeyboardSelection } from './keyboard-selection';
import type { NavigationCommand } from 'core-app/shared/helpers/navigation-keys';
import { type ActivationKey, cellIntent, type KeyIntent } from './key-intent';
import {
  insideGrid, insideGridContent, navigableCellClassName, navigableCells, paintRovingTabindex, rovingStopSelector,
} from './roving-tabindex';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { CellInteraction } from './cell-interaction';
import { FocusCursor } from './focus-cursor';

const navigableKinds:ReadonlySet<RowRecordKind> = new Set(ROW_KINDS);

function isNavigableKind(kind:RowRecordKind):kind is RowKind {
  return navigableKinds.has(kind);
}

function navigableRow({ element, occurrence, state }:RowRecord, key:string, kind:RowKind):NavigableRow {
  const row:NavigableRow = {
    key,
    kind,
    hidden: state.hidden,
    cellCount: navigableCells(element).length,
    expanded: state.expanded,
  };
  return occurrence?.groupIdentifier === undefined ? row : { ...row, groupIdentifier: occurrence.groupIdentifier };
}

/** The rows keyboard navigation walks, in visual order: header, rendered occurrences, totals. */
function buildNavigableRows(table:WorkPackageTable):NavigableRow[] {
  return table.rows.rows().flatMap((record) => {
    const { key, state: { kind } } = record;
    return key !== null && isNavigableKind(kind) ? [navigableRow(record, key, kind)] : [];
  });
}

export interface KeyboardNavigation {
  readonly position:FocusPosition|null;
  /** False once focus moved to a control outside the table and its editors, until it returns. */
  readonly retainsFocus:boolean;
  /** Makes the position the table's Tab stop, focuses it and scrolls it into view. */
  focusPosition(position:FocusPosition):void;
  /** Remembers the position without painting or focusing it. */
  recordPosition(position:FocusPosition):void;
  rememberWorkPackageAfterRender(workPackageId:string):void;
  /** Focuses the origin again, or the row hiding it, unless the user has since moved elsewhere, an editor is open or focus rests on a live control; true when it focused. */
  returnFocus(origin:FocusPosition, closing?:EditFieldHandler):boolean;
  /** Returns focus to `origin` after a menu closed, though focus visited the menu portal; same userPosition guard as returnFocus, and never takes focus from a control outside the table. */
  returnFocusFromMenu(origin:FocusPosition):void;
  /** The position of the navigable cell or row enclosing `cell`, or null when it is not a rendered occurrence. */
  positionOfCell(cell:HTMLElement):FocusPosition|null;
  originForControl(control:HTMLElement):FocusPosition|null;
  /** The row or cell element at the position, or null when it is not rendered. */
  elementAt(position:FocusPosition):HTMLElement|null;
  /** Records whether focus is inside the table before a mutation replaces or hides its rows; `accumulate` keeps an earlier capture while an outer mutation or a pending render is open. */
  captureOwnership(accumulate:boolean):void;
  /** Recovers the focus position after a mutation settled; `rendered` means a render committed. */
  rowsChanged(exit:MutationExit):void;
  /** Keeps the return path open when an editor registers an overlay that already holds focus. */
  adoptOverlay(overlay:HTMLElement):void;
  /** Engages a parked editor and focuses its overlay or first focusable control. */
  focusEditor(handler:EditFieldHandler):void;
  repaintCurrentPosition():void;
  /** Moves by `command` from `position`, as if focus rested there. */
  navigateFrom(position:FocusPosition, command:NavigationCommand):void;
  scrollControlIntoView(control:HTMLElement):void;
}

interface RenderedRows {
  rows:NavigableRow[];
  groupBy:string|null;
}

const pointerEndEvents = ['mouseup', 'click', 'pointerup', 'pointercancel', 'dragend'] as const;

/** Moves focus across the rows and cells of a table with the keyboard. */
export class KeyboardNavigationTransformer implements KeyboardNavigation {
  @LazyInject() public querySpace:IsolatedQuerySpace;

  @LazyInject() public wpTableHierarchies:WorkPackageViewHierarchiesService;

  @LazyInject() public collapsedGroups:WorkPackageViewCollapsedGroupsService;

  @LazyInject() public wpTableFocus:WorkPackageViewFocusService;

  @LazyInject() public wpTableSelection:WorkPackageViewSelectionService;

  private readonly cursor = new FocusCursor((position) => this.paintRoving(position && this.elementAt(position)));

  private owned = false;

  private rememberedAfterRender:{
    position:FocusPosition;
    requestedFrom:FocusPosition|null;
  }|null = null;

  private focusLeftTable = false;

  private pointerActive = false;

  private rendered:RenderedRows = { rows: [], groupBy: null };

  private readonly selecting:KeyboardSelection;

  private readonly interaction:CellInteraction;

  constructor(
    public readonly injector:Injector,
    private readonly table:WorkPackageTable,
    private readonly view:TableEventComponent|null = null,
  ) {
    const { destroyRef, scrollContainer } = table;
    table.attachKeyboardNavigation(this);
    this.selecting = new KeyboardSelection(table, this.wpTableSelection);
    this.interaction = new CellInteraction(table, this.cursor);
    const removedFromTabOrder = [scrollContainer, table.tableAndTimelineContainer]
      .filter((container, index, containers) => containers.indexOf(container) === index && !container.hasAttribute('tabindex'));
    removedFromTabOrder.forEach((container) => container.setAttribute('tabindex', '-1'));
    onDestroySafely(destroyRef, () => {
      removedFromTabOrder.forEach((container) => container.removeAttribute('tabindex'));
    });

    const listeners = new AbortController();
    const { signal } = listeners;
    const onKeydown = (event:KeyboardEvent) => this.handleKeydown(event);
    const onFocusin = (event:FocusEvent) => {
      const target = event.target as Node;
      this.focusLeftTable = !insideGrid(scrollContainer, target) && !table.editing.owns(target);
      const from = event.relatedTarget;
      this.interaction.engageFocusedEditor(event.target);
      if (table.editing.gridFieldOwning(from as Node|null)) {
        this.interaction.preparePaint();
      }
      this.adoptFocus(event.target as HTMLElement, !insideGrid(scrollContainer, from as Node|null));
    };
    const onFocusout = (event:FocusEvent) => {
      const next = event.relatedTarget ?? event.target;
      this.focusLeftTable = !insideGrid(scrollContainer, next as Node) && !table.editing.owns(next as Node);
      if (this.focusLeftTable) this.cursor.clearWalk();
    };
    const onDocumentFocusin = (event:FocusEvent) => {
      const target = event.target as Node;
      const related = event.relatedTarget as Node|null;
      if (table.editing.owns(target) || table.editing.owns(related)) {
        this.focusLeftTable = !insideGrid(scrollContainer, target) && !table.editing.owns(target);
      }
      if (!insideGrid(scrollContainer, target) && table.editing.gridFieldOwning(related)) {
        this.interaction.preparePaint();
      }
    };
    scrollContainer.addEventListener('keydown', onKeydown, { signal });
    const onMousedown = (event:MouseEvent) => {
      this.pointerActive = true;
      this.cursor.clearWalk();
      this.recordPointerTarget(event.target);
    };
    const onPointerEnd = () => { this.pointerActive = false; };
    scrollContainer.addEventListener('focusin', onFocusin, { signal });
    scrollContainer.addEventListener('focusout', onFocusout, { signal });
    scrollContainer.addEventListener('mousedown', onMousedown, { signal });
    document.addEventListener('focusin', onDocumentFocusin, { signal });
    pointerEndEvents.forEach((type) => document.addEventListener(type, onPointerEnd, { signal }));
    onDestroySafely(destroyRef, () => listeners.abort());

  }

  public get position():FocusPosition|null {
    return this.cursor.position;
  }

  public get retainsFocus():boolean {
    return !this.focusLeftTable;
  }

  public focusPosition(position:FocusPosition):void {
    if (this.table.destroyed) return;
    const element = this.moveFocusTo(position);
    if (element) {
      this.scrollIntoView(element);
    }
  }

  public recordPosition(position:FocusPosition):void {
    if (this.table.destroyed) return;
    this.cursor.land(position, { user: true, paint: false });
  }

  public rememberWorkPackageAfterRender(workPackageId:string):void {
    if (this.table.destroyed) return;
    this.rememberedAfterRender = {
      position: rowPosition(wpOccurrenceKey(workPackageId)),
      requestedFrom: this.cursor.userPosition,
    };
  }

  public focusEditor(handler:EditFieldHandler):void {
    if (this.table.destroyed) return;
    this.interaction.focusEditor(handler);
  }

  public captureOwnership(accumulate:boolean):void {
    if (this.table.destroyed) return;
    const active = document.activeElement;
    const inside = insideGrid(this.table.scrollContainer, active) || this.table.editing.gridFieldOwning(active) !== null;
    this.owned = accumulate ? this.owned || inside : inside;
  }

  public rowsChanged({ scope, rendered }:MutationExit):void {
    if (this.table.destroyed) return;
    this.recover(rendered ? this.requestedPosition() : null, !rendered, this.rowsOf(scope));
  }

  /** The rows a keyed scope names; null when the whole table needs its Tab stops repainted. */
  private rowsOf(scope:PaintScope):HTMLTableRowElement[]|null {
    if (scope === 'all' || scope === 'positions') return null;
    return Array.from(scope)
      .map((key) => this.rowElement(key))
      .filter((row):row is HTMLTableRowElement => row !== null);
  }

  public adoptOverlay(overlay:HTMLElement):void {
    if (this.table.destroyed) return;
    if (overlay.contains(document.activeElement)) {
      this.focusLeftTable = false;
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

  public returnFocus(origin:FocusPosition, closing?:EditFieldHandler):boolean {
    if (this.table.destroyed) return false;
    const rows = buildNavigableRows(this.table);
    const originIndex = rows.findIndex((row) => row.key === origin.key);
    const target = originIndex === -1 ? this.cursor.position : reconcilePosition(rows, origin, originIndex);
    const { userPosition } = this.cursor;
    const userIndex = userPosition ? rows.findIndex((row) => row.key === userPosition.key) : -1;
    const user = userPosition && userIndex !== -1 ? reconcilePosition(rows, userPosition, userIndex) : null;
    if (!target || !this.mayRestoreFocus(closing) || (user && !samePosition(user, target))) {
      return false;
    }

    this.focusPosition(target);
    return true;
  }

  public positionOfCell(cell:Element):FocusPosition|null {
    if (this.table.destroyed) return null;
    return this.positionOf(cell.closest<HTMLElement>(`.${navigableCellClassName}`) ?? cell.closest('tr'));
  }

  public originForControl(control:HTMLElement):FocusPosition|null {
    if (this.table.destroyed) return null;
    return this.interaction.originForControl(control);
  }

  public elementAt(position:FocusPosition):HTMLElement|null {
    if (this.table.destroyed) return null;
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
      requested = rowPosition(wpOccurrenceKey(workPackageId));
    });
    return requested;
  }

  private recover(requested:FocusPosition|null, retainStop = false, changedRows:HTMLElement[]|null = null):void {
    const owned = this.owned;
    if (!this.table.hasPendingRender) {
      this.owned = false;
    }
    const previous = this.rendered;
    const rows = buildNavigableRows(this.table);
    this.rendered = { rows, groupBy: this.groupBy() };

    if (requested && this.elementAt(requested)) {
      this.cursor.noteUserMove(requested);
      this.focusPosition(requested);
      return;
    }

    const remembered = this.rememberedAfterRender;
    if (remembered && this.cursor.userMovedSince(remembered.requestedFrom)) {
      this.rememberedAfterRender = null;
    } else if (remembered && this.elementAt(remembered.position)) {
      this.rememberedAfterRender = null;
      this.recordPosition(remembered.position);
      if (owned && this.mayRestoreFocus()) {
        this.focusPosition(remembered.position);
      } else {
        this.paintRoving(this.elementAt(remembered.position), changedRows);
      }
      return;
    }

    this.interaction.reconcileWalk();
    const previousPosition = this.cursor.position;
    this.cursor.reconcile(previousPosition && this.reconcile(rows, previous, previousPosition));
    const current = this.cursor.position;
    if (current && owned && this.mayRestoreFocus()) {
      this.focusPosition(current);
      return;
    }

    const painted = current ?? (retainStop ? this.retainedStop(rows) : null) ?? initialPosition(rows);
    this.paintRoving(painted && this.elementAt(painted), changedRows);
  }

  /** The position of the row or cell that still carries the Tab stop, when it is still a visible navigable row, so a mutation that kept it does not move it to the first row. */
  private retainedStop(rows:readonly NavigableRow[]):FocusPosition|null {
    const stop = this.table.scrollContainer.querySelector<HTMLElement>(rovingStopSelector);
    const position = stop ? this.positionOf(stop) : null;
    return position && rows.some((row) => row.key === position.key && !row.hidden) ? position : null;
  }

  private reconcile(rows:NavigableRow[], previous:RenderedRows, position:FocusPosition):FocusPosition|null {
    if (!rows.some((row) => row.kind !== 'header' && row.kind !== 'totals')) {
      const header = rows.find((row) => row.kind === 'header');
      return header ? rowPosition(header.key) : null;
    }

    const previousIndex = previous.rows.findIndex((row) => row.key === position.key);
    const regrouped = position.groupIdentifier !== undefined && previous.groupBy !== this.rendered.groupBy;
    return regrouped ? nearestPosition(rows, previousIndex) : reconcilePosition(rows, position, previousIndex);
  }

  private mayRestoreFocus(closing?:EditFieldHandler):boolean {
    const editing = this.table.editing.owns(document.activeElement);
    return !editing && !this.focusLeftTable && this.focusAtRest(closing);
  }

  private focusAtRest(closing?:EditFieldHandler):boolean {
    const active = document.activeElement;
    return !active
      || active === document.body
      || !active.isConnected
      || !!closing?.owns(active)
      || (insideGridContent(this.table.scrollContainer, active) && this.hiddenOrUnlisted(active));
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
    const current = this.cursor.position;
    if (current && this.elementAt(current) === target) {
      this.cursor.clearWalk();
      return;
    }

    const position = this.positionOf(target);
    if (position) {
      this.cursor.land(position, { user: true, paint: false });
      this.paintRoving(target);
      return;
    }

    if (!fromOutside && !this.table.editing.owns(target)) {
      this.interaction.reconcileWalk();
      const origin = this.interaction.originForControl(target);
      if (origin) {
        this.cursor.follow(origin);
      }
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

    this.cursor.land(position, { user: false, paint: false });
    this.paintRoving(element);
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
      this.cursor.land(position, { user: true, paint: true });
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
    if (!insideGrid(this.table.scrollContainer, event.target as Node)) return;

    const position = this.cursor.position;
    if (position && event.key === 'Tab' && event.target === this.elementAt(position)) {
      this.interaction.tabFromOrigin(event, position);
      return;
    }

    if (this.interaction.handleInnerKeydown(event)) {
      event.preventDefault();
      return;
    }

    if (!position || event.target !== this.elementAt(position)) {
      return;
    }

    const intent = cellIntent(event, isApplePlatform());
    let handled:boolean;
    switch (intent.type) {
      case 'selection':
        this.handleSelectionChord(position, intent, event);
        return;
      case 'activate':
        handled = this.activate(position, intent.key);
        break;
      case 'move':
        handled = this.navigate(position, intent.command);
        break;
      default:
        return;
    }

    if (handled) {
      event.preventDefault();
    }
  }

  private handleSelectionChord(position:FocusPosition, intent:Extract<KeyIntent, { type:'selection' }>, event:KeyboardEvent):void {
    switch (intent.chord) {
      case 'toggle':
        if (this.selecting.occurrenceAt(position)) {
          event.preventDefault();
          if (!event.repeat) {
            this.selecting.toggle(position);
          }
        }
        return;
      case 'selectAll':
        if (selectableOccurrences(this.table.renderedRows).length > 0) {
          event.preventDefault();
          if (!event.repeat) {
            this.selecting.selectAll(position);
          }
        }
        return;
      case 'extend':
        event.preventDefault();
        this.extendSelection(position, intent.command);
    }
  }

  private extendSelection(position:FocusPosition, command:NavigationCommand):void {
    this.navigate(position, command);
    const arrived = this.cursor.position;
    if (arrived && !samePosition(arrived, position)) {
      this.selecting.extendTo(arrived);
    }
  }

  public navigateFrom(position:FocusPosition, command:NavigationCommand):void {
    if (this.table.destroyed) return;
    this.navigate(position, command);
  }

  public scrollControlIntoView(control:HTMLElement):void {
    if (this.table.destroyed) return;
    this.scrollIntoView(control);
  }

  private navigate(position:FocusPosition, command:NavigationCommand):boolean {
    const rows = buildNavigableRows(this.table);
    const result = computeNextPosition(rows, position, command, this.pageSize(rows));
    switch (result.type) {
      case 'move':
        this.cursor.noteUserMove(result.position);
        this.focusPosition(result.position);
        return true;
      case 'expand':
      case 'collapse':
        this.toggle(result.row);
        this.focusPosition(position);
        return true;
      default:
        return true;
    }
  }

  private toggle(row:NavigableRow):void {
    if (row.kind === 'groupHeader') {
      this.toggleGroup(row.groupIdentifier);
      return;
    }

    const workPackageId = this.table.ledger.byKey(row.key)?.workPackageId;
    if (workPackageId) {
      this.wpTableHierarchies.toggle(workPackageId);
    }
  }

  private toggleGroup(groupIdentifier:string|undefined):void {
    if (groupIdentifier !== undefined) this.collapsedGroups.toggleGroupCollapseState(groupIdentifier);
  }

  private activate(position:FocusPosition, key:ActivationKey):boolean {
    if (position.cell !== null) {
      if (position.key === headerRowKey) {
        return key === 'Enter' && this.clickHeaderControl(this.elementAt(position));
      }

      const occurrence = this.table.ledger.byKey(position.key);
      if (occurrence && rowKindOf(occurrence) === 'groupHeader' && key === 'Enter') {
        this.toggleGroup(occurrence.groupIdentifier);
        this.focusPosition(position);
        return true;
      }

      return this.interaction.enter(position, key);
    }

    const occurrence = this.table.ledger.byKey(position.key);
    if (!occurrence || key === 'F2') {
      return false;
    }

    switch (rowKindOf(occurrence)) {
      case 'groupHeader':
        this.toggleGroup(occurrence.groupIdentifier);
        this.focusPosition(position);
        return true;
      case 'workPackage':
        return isSelectableOccurrence(occurrence) && this.activateWorkPackageRow(occurrence.workPackageId, occurrence.element);
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

  public repaintCurrentPosition():void {
    if (this.table.destroyed) return;
    const current = this.cursor.position;
    if (current) {
      this.paintRoving(this.elementAt(current));
    }
  }

  /** With `changedRows`, the rows outside them keep the Tab stops they were painted with, so only those rows, the old stop and `focused` are repainted. */
  private paintRoving(focused:HTMLElement|null, changedRows:HTMLElement[]|null = null):void {
    const engaged = this.interaction.preparePaint();
    if (changedRows === null) {
      paintRovingTabindex(this.table.scrollContainer, focused, engaged);
      return;
    }
    const stop = this.table.scrollContainer.querySelector<HTMLElement>(rovingStopSelector);
    const roots = [...changedRows, stop, focused].filter((root):root is HTMLElement => root !== null);
    paintRovingTabindex(roots, focused, engaged);
  }

  private scrollIntoView(element:HTMLElement):void {
    if (this.table.tbody.contains(element)) {
      element.style.scrollMarginTop = `${headerRowOf(this.table)?.getBoundingClientRect().height ?? 0}px`;
    }
    element.scrollIntoView({ block: 'nearest', inline: 'nearest' });
  }
}
