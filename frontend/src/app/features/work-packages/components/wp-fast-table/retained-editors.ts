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

import { focusIsUnclaimed } from 'core-app/shared/helpers/focus-helpers';
import { editFieldContainerClass } from 'core-app/shared/components/fields/display/display-field-renderer';
import type { WorkPackageTable } from './wp-fast-table';
import type { ActiveTableField } from './wp-table-editing';
import { baselineLayoutClassNames, tdClassName } from './builders/cell-builder';
import type { OccurrenceKey } from './rendered-occurrence-ledger';
import type { PositionMove } from './handlers/state/keyboard/focus-position';

interface CapturedField extends ActiveTableField {
  readonly fieldName:string;
  readonly host:HTMLElement;
  readonly key:OccurrenceKey|undefined;
  readonly retainable:boolean;
}

interface RetainedField extends CapturedField {
  readonly move:PositionMove|null;
}

interface FreshSlot {
  readonly cell:HTMLTableCellElement;
  readonly host:HTMLElement;
}

interface FocusSnapshot {
  readonly element:HTMLElement;
  readonly selection:{ start:number, end:number, direction:'forward'|'backward'|'none' }|null;
}

function isTextControl(element:Element):element is HTMLInputElement|HTMLTextAreaElement {
  return element instanceof HTMLInputElement || element instanceof HTMLTextAreaElement;
}

function readSelection(element:HTMLElement):FocusSnapshot['selection'] {
  if (!isTextControl(element)) return null;
  try {
    const { selectionStart, selectionEnd, selectionDirection } = element;
    if (selectionStart === null || selectionEnd === null) return null;
    return { start: selectionStart, end: selectionEnd, direction: selectionDirection ?? 'none' };
  } catch {
    return null;
  }
}

export class RetainedEditors {
  private constructor(
    private readonly table:WorkPackageTable,
    private readonly fields:readonly CapturedField[],
    private readonly focus:FocusSnapshot|null,
  ) {}

  static capture(table:WorkPackageTable):RetainedEditors {
    const fields = table.editing.activeTableFields().flatMap((field):CapturedField[] => {
      const host = field.handler.element;
      if (!host || !table.tbody.contains(host)) return [];
      return [{
        ...field,
        fieldName: field.handler.fieldName,
        host,
        key: host.closest('tr')?.dataset.occurrenceKey,
        retainable: table.editing.retains(field),
      }];
    });

    const active = document.activeElement;
    const focused = active instanceof HTMLElement && fields.some(({ host }) => host.contains(active)) ? active : null;
    return new RetainedEditors(table, fields, focused && { element: focused, selection: readSelection(focused) });
  }

  restore():void {
    if (this.table.destroyed) return;
    const retained = this.fields.flatMap((field):RetainedField[] => {
      if (field.form.activeFields[field.fieldName] !== field.handler) return [];
      const slot = this.freshSlotFor(field);
      if (slot) return [this.retain(field, slot)];
      this.release(field);
      return [];
    });
    this.follow(retained);
    retained.forEach((field) => this.refocus(field));
  }

  private freshSlotFor({ retainable, key, fieldName }:CapturedField):FreshSlot|null {
    if (!retainable || key === undefined) return null;
    const occurrence = this.table.ledger.byKey(key);
    if (!occurrence?.element || occurrence.hidden) return null;
    const cell = occurrence.element.querySelector<HTMLTableCellElement>(`.${tdClassName}.${fieldName}`);
    const host = cell?.querySelector<HTMLElement>(`.${editFieldContainerClass}`);
    return cell && host ? { cell, host } : null;
  }

  private retain(field:CapturedField, { cell, host }:FreshSlot):RetainedField {
    const move = field.form.adoptCell(field.fieldName, cell);
    field.host.style.width = host.style.width;
    baselineLayoutClassNames.forEach((name) => field.host.classList.toggle(name, host.classList.contains(name)));
    host.replaceWith(field.host);
    return { ...field, move };
  }

  private release({ form, handler }:CapturedField):void {
    handler.deactivate(false);
    this.table.editing.retireIfEmpty(form.workPackageId);
  }

  private focusedIn(host:HTMLElement):boolean {
    return !!this.focus && host.contains(this.focus.element);
  }

  private follow(retained:readonly RetainedField[]):void {
    const moves = retained.flatMap(({ move }) => (move ? [move] : []));
    new Set(retained.map(({ form }) => form)).forEach((form) => form.rebaseSubmitted(moves));

    const navigation = this.table.keyboardNavigation;
    const focused = retained.find(({ host }) => this.focusedIn(host));
    const focusedAt = focused ? focused.move?.current ?? navigation.positionOfCell(focused.host) : null;
    navigation.followRetained(moves, focusedAt);
  }

  private refocus({ host }:CapturedField):void {
    const snapshot = this.focus;
    if (!snapshot || !host.contains(snapshot.element)) return;
    if (!snapshot.element.isConnected || !focusIsUnclaimed()) return;

    snapshot.element.focus({ preventScroll: true });
    const { selection } = snapshot;
    if (selection && isTextControl(snapshot.element)) {
      snapshot.element.setSelectionRange(selection.start, selection.end, selection.direction);
    }
  }
}
