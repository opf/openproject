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

import type { WorkPackageTable } from '../../../wp-fast-table';
import type { KeyboardNavigation } from './keyboard-navigation-transformer';
import { FocusPosition } from './focus-position';
import { displayClassName, displayTriggerLink, editableClassName } from 'core-app/shared/components/fields/display/display-field-renderer';
import { activeFieldContainerClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { activateTableField } from '../../cell/edit-cell-handler';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { navigableCells } from './roving-tabindex';
import { headerRowKey } from './navigable-rows';
import type { ActiveTableField } from '../../../wp-table-editing';

const controlSelector = 'a[href], button, input, select, textarea, [role="button"]';
const editorTabStopSelector = 'a[href], button, input, select, textarea, [tabindex]';
const originalTabindex = 'data-op-original-tabindex';

function rendered(element:HTMLElement):boolean {
  return element.checkVisibility() && !element.closest('[aria-hidden="true"]');
}

function enabled(element:HTMLElement):boolean {
  return !element.matches(':disabled') && !element.closest('fieldset:disabled, [aria-disabled="true"]');
}

export function cellTargets(cell:HTMLElement, table?:WorkPackageTable):HTMLElement[] {
  return Array.from(cell.querySelectorAll<HTMLElement>(controlSelector)).filter((element) =>
    rendered(element)
      && enabled(element)
      && !element.closest(`.${displayTriggerLink}`)
      && !element.closest(`.${activeFieldContainerClassName}`)
      && !table?.editing.owns(element));
}

export function rowControls(row:HTMLTableRowElement, table?:WorkPackageTable):HTMLElement[] {
  return navigableCells(row).flatMap((cell) => cellTargets(cell, table));
}

export class CellInteraction {
  private tabWalkOrigin:FocusPosition|null = null;

  private readonly parked = new WeakSet<EditFieldHandler>();

  constructor(private readonly table:WorkPackageTable) {}

  private get navigation():KeyboardNavigation {
    return this.table.keyboardNavigation!;
  }

  public enter(position:FocusPosition, key:'Enter'|'F2'):boolean {
    const cell = this.navigation.elementAt(position);
    if (!cell) return false;

    const open = this.table.editing.fieldForCell(cell);
    if (open) {
      open.form.engageOrigin(open.handler.fieldName);
      this.engageEditor(open.handler);
      const overlayTarget = this.overlayFocusTarget(open.handler);
      if (overlayTarget) {
        overlayTarget.focus({ preventScroll: true });
      } else {
        open.handler.focus();
      }
      return true;
    }

    const editable = cell.querySelector<HTMLElement>(`.${displayClassName}.${editableClassName}`);
    if (key === 'F2' || editable) {
      return !!editable && activateTableField(this.table, editable);
    }

    const targets = cellTargets(cell, this.table);
    if (targets.length === 1) {
      targets[0].click();
      return true;
    }

    if (targets.length > 1) {
      this.tabWalkOrigin = position;
      targets[0].focus({ preventScroll: true });
      return true;
    }

    return false;
  }

  public preparePaint():HTMLElement|null {
    const engaged = this.table.editing.gridFieldOwning(document.activeElement);
    this.table.editing.activeGridFields().forEach(({ handler }) => {
      if (handler !== engaged?.handler) this.park(handler);
    });
    return engaged?.handler.element?.querySelector<HTMLElement>(`.${activeFieldContainerClassName}`) ?? null;
  }

  public engageEditor(handler:EditFieldHandler):void {
    const active = this.table.editing.activeTableFields().find(({ handler: candidate }) => candidate === handler);
    active?.form.engageOrigin(handler.fieldName);
    this.parked.delete(handler);
    this.editorElements(handler).forEach((element) => {
      const savedElements = element.hasAttribute(originalTabindex) ? [element] : [];
      [...savedElements, ...element.querySelectorAll<HTMLElement>(`[${originalTabindex}]`)].forEach((tabbable) => {
        const saved = tabbable.getAttribute(originalTabindex);
        if (saved === '__absent__') {
          tabbable.removeAttribute('tabindex');
        } else if (saved !== null) {
          tabbable.setAttribute('tabindex', saved);
        }
        tabbable.removeAttribute(originalTabindex);
      });
    });
  }

  public engageFocusedEditor(target:EventTarget|null):void {
    const active = this.table.editing.gridFieldOwning(target as Node|null);
    if (active && this.parked.has(active.handler)) {
      this.engageEditor(active.handler);
    }
  }

  public handleInnerKeydown(event:KeyboardEvent):boolean {
    const active = this.table.editing.gridFieldOwning(event.target as Node);
    if (active) {
      if (event.key !== 'Tab') return false;
      return this.handleEditorTab(event, active.handler, active.form);
    }

    if (event.key !== 'Tab' && event.key !== 'Escape' && !this.isNavigationKey(event)) return false;
    const target = event.target as HTMLElement;
    const origin = event.key === 'Tab'
      ? this.tabWalkOrigin ?? this.navigation.positionOfCell(target)
      : this.tabWalkOrigin;
    if (!origin) return false;

    this.navigation.repaintCurrentPosition();
    const targets = this.walkFrom(origin);
    const index = targets.indexOf(target);
    if (index === -1) return false;

    if (event.key === 'Escape') {
      event.preventDefault();
      this.navigation.focusPosition(origin);
      return true;
    }

    if (this.isNavigationKey(event)) {
      event.preventDefault();
      this.navigation.focusPosition(origin);
      this.navigation.navigateFrom(origin, event);
      return true;
    }

    this.tabWalkOrigin = origin;
    if (event.shiftKey) {
      event.preventDefault();
      const previous = index > 0 ? targets[index - 1] : this.navigation.elementAt(origin);
      previous?.focus({ preventScroll: true });
      if (previous) this.navigation.scrollControlIntoView(previous);
      return true;
    }

    if (index === targets.length - 1) return false;

    event.preventDefault();
    const next = targets[index + 1];
    next.focus({ preventScroll: true });
    this.navigation.scrollControlIntoView(next);
    return true;
  }

  private handleEditorTab(event:KeyboardEvent, handler:EditFieldHandler, form:ActiveTableField['form']):boolean {
    const container = handler.element;
    if (!container?.contains(event.target as Node)) return false;

    const tabbables = this.editorTabStops(handler).filter((element) => container.contains(element) && element.tabIndex >= 0);
    const index = tabbables.indexOf(event.target as HTMLElement);
    const boundary = event.shiftKey ? index === 0 : index === tabbables.length - 1;
    if (!boundary) return false;

    const origin = form.originFor(handler.fieldName)
      ?? this.navigation.positionOfCell(handler.element!)
      ?? this.navigation.position;
    if (!origin) return false;

    event.preventDefault();
    this.park(handler);
    this.navigation.focusPosition(origin);
    return true;
  }

  private park(handler:EditFieldHandler):void {
    this.parked.add(handler);
    this.editorControls(handler).forEach((element) => {
      if (!element.hasAttribute(originalTabindex)) {
        element.setAttribute(originalTabindex, element.getAttribute('tabindex') ?? '__absent__');
      }
      element.setAttribute('tabindex', '-1');
    });
  }

  private editorElements(handler:EditFieldHandler):HTMLElement[] {
    return [handler.element!, ...handler.overlays];
  }

  private editorControls(handler:EditFieldHandler):HTMLElement[] {
    return this.editorElements(handler).flatMap((root) => {
      const candidates = root.matches(editorTabStopSelector) ? [root] : [];
      return [...candidates, ...root.querySelectorAll<HTMLElement>(editorTabStopSelector)];
    });
  }

  private editorTabStops(handler:EditFieldHandler):HTMLElement[] {
    return this.editorControls(handler)
      .filter((element) => rendered(element) && enabled(element))
      .filter((element) => element.tabIndex >= 0 || element.hasAttribute(originalTabindex));
  }

  private overlayFocusTarget(handler:EditFieldHandler):HTMLElement|null {
    const [overlay] = handler.overlays;
    if (!overlay) return null;

    const candidates = Array.from(overlay.querySelectorAll<HTMLElement>(controlSelector));
    return candidates.find((element) => rendered(element) && enabled(element)) ?? overlay;
  }

  public tabFromOrigin(event:KeyboardEvent, origin:FocusPosition):void {
    this.navigation.repaintCurrentPosition();
    if (event.shiftKey) return;

    const targets = this.walkFrom(origin);
    if (targets.length === 0) return;

    event.preventDefault();
    this.tabWalkOrigin = origin;
    targets[0].focus({ preventScroll: true });
    this.navigation.scrollControlIntoView(targets[0]);
  }

  private walkFrom(origin:FocusPosition):HTMLElement[] {
    const element = this.navigation.elementAt(origin);
    const row = element?.closest<HTMLTableRowElement>('tr');
    if (!row || origin.key === headerRowKey) return [];
    if (origin.cell === null) return rowControls(row, this.table);

    return navigableCells(row).slice(origin.cell).flatMap((cell) => cellTargets(cell, this.table));
  }

  private isNavigationKey(event:KeyboardEvent):boolean {
    return !event.shiftKey && !event.altKey && ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Home', 'End', 'PageUp', 'PageDown'].includes(event.key);
  }

  public originForControl(control:HTMLElement):FocusPosition|null {
    return this.tabWalkOrigin ?? this.navigation.positionOfCell(control);
  }

  public clearWalk():void {
    this.tabWalkOrigin = null;
  }
}
