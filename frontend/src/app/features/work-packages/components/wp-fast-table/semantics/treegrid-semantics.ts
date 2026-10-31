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
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { isSelectableOccurrence } from 'core-app/features/work-packages/routing/wp-view-base/view-services/rendered-occurrences';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { baselineStatusName } from '../builders/baseline/baseline-column-builder';
import { paintRowSelection } from '../builders/rows/row-selection-painter';
import { expansionStateOf } from '../helpers/row-expansion';
import { occurrenceRowKind, type OccurrenceRowKind } from '../helpers/structural-rows';
import type { RenderedOccurrence } from '../rendered-occurrence-ledger';
import type { WorkPackageTable } from '../wp-fast-table';

export function setOrRemove(element:Element, name:string, value:string|null):void {
  if (value === null) {
    if (element.hasAttribute(name)) element.removeAttribute(name);
  } else if (element.getAttribute(name) !== value) {
    element.setAttribute(name, value);
  }
}

export function paintRowRole(
  row:HTMLTableRowElement,
  level:number,
  cellRole:'gridcell'|'columnheader' = 'gridcell',
  nameIdPrefix:string|null = null,
):void {
  setOrRemove(row, 'role', 'row');
  setOrRemove(row, 'aria-level', String(level));
  let header:HTMLTableCellElement|undefined;
  Array.from(row.cells).forEach((cell) => {
    if (cellRole === 'gridcell' && cell.matches('th[scope="row"]')) {
      header = cell;
      setOrRemove(cell, 'role', null);
      setOrRemove(cell, 'aria-labelledby', null);
      setOrRemove(cell, 'aria-label', cell.dataset.rowHeaderName ?? null);
    } else {
      setOrRemove(cell, 'role', cellRole);
    }
  });
  const named = header && nameIdPrefix !== null ? header : null;
  const status = named ? row.querySelector<HTMLElement>(`:scope > td .${baselineStatusName}`) : null;
  setOrRemove(row, 'aria-labelledby', named ? assignId(named, `${nameIdPrefix}-header`) : null);
  setOrRemove(row, 'aria-describedby', status ? assignId(status, `${nameIdPrefix}-status`) : null);
}

function assignId(element:HTMLElement, id:string):string {
  setOrRemove(element, 'id', id);
  return id;
}

export function paintSectionExposure(section:HTMLTableSectionElement):void {
  setOrRemove(section, 'role', 'rowgroup');
  const exposed = Array.from(section.rows).some((row) => row.getAttribute('aria-hidden') !== 'true');
  setOrRemove(section, 'aria-hidden', exposed ? null : 'true');
}

export class TreegridSemantics {
  @LazyInject() private readonly wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() private readonly wpTableHierarchies:WorkPackageViewHierarchiesService;

  @LazyInject() private readonly wpTableFocus:WorkPackageViewFocusService;

  public readonly injector:Injector = this.table.injector;

  constructor(private readonly table:WorkPackageTable) {}

  public paint():void {
    if (this.table.destroyed) return;
    this.table.ledger.occurrences.forEach((occurrence) => this.paintOccurrence(occurrence));
    paintSectionExposure(this.table.tbody);
  }

  public paintKeys(keys:ReadonlySet<string>):void {
    if (this.table.destroyed) return;
    keys.forEach((key) => {
      const occurrence = this.table.ledger.byKey(key);
      if (occurrence) this.paintOccurrence(occurrence);
    });
  }

  private paintOccurrence(occurrence:RenderedOccurrence):void {
    const row = occurrence.element;
    if (!row) return;

    const kind = occurrenceRowKind(occurrence);
    if (kind === 'placeholder') {
      setOrRemove(row, 'aria-hidden', 'true');
      return;
    }

    paintRowRole(row, occurrence.level, 'gridcell', `${this.table.domId}-${occurrence.key}`);
    setOrRemove(row, 'aria-expanded', this.expansionOf(occurrence, kind));
    this.paintSelected(occurrence);
  }

  private paintSelected(occurrence:RenderedOccurrence):void {
    const row = occurrence.element;
    if (!row || !isSelectableOccurrence(occurrence)) return;
    const selected = this.wpTableSelection.isSelected(occurrence.workPackageId);
    const pressed = this.wpTableFocus.isFocused(occurrence.workPackageId);
    setOrRemove(row, 'aria-selected', String(selected));
    setOrRemove(row, 'data-pressed', pressed ? '' : null);
    paintRowSelection(row, { selected, pressed });
  }

  private expansionOf(occurrence:RenderedOccurrence, kind:Exclude<OccurrenceRowKind, 'placeholder'>):string|null {
    const expanded = expansionStateOf(this.table, this.wpTableHierarchies, occurrence, kind);
    return expanded === null ? null : String(expanded);
  }
}
