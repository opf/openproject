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

const controlSelector = 'a[href], button, input, select, textarea, [role="button"]';

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

  public engageEditor(handler:EditFieldHandler):void {
    const active = this.table.editing.activeTableFields().find(({ handler: candidate }) => candidate === handler);
    active?.form.engageOrigin(handler.fieldName);
  }

  public handleInnerKeydown(_event:KeyboardEvent):boolean {
    return false;
  }

  private overlayFocusTarget(handler:EditFieldHandler):HTMLElement|null {
    const [overlay] = handler.overlays;
    if (!overlay) return null;

    const candidates = Array.from(overlay.querySelectorAll<HTMLElement>(controlSelector));
    return candidates.find((element) => rendered(element) && enabled(element)) ?? overlay;
  }

  public tabFromOrigin(_event:KeyboardEvent, _origin:FocusPosition):boolean {
    return false;
  }

  public originForControl(control:HTMLElement):FocusPosition|null {
    return this.tabWalkOrigin ?? this.navigation.positionOfCell(control);
  }

  public clearWalk():void {
    this.tabWalkOrigin = null;
  }
}
