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
import { isSelectableOccurrence } from 'core-app/features/work-packages/routing/wp-view-base/view-services/rendered-occurrences';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
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

export function paintRowRole(row:HTMLTableRowElement, level:number, cellRole:'gridcell'|'columnheader' = 'gridcell'):void {
  row.setAttribute('role', 'row');
  row.setAttribute('aria-level', String(level));
  Array.from(row.cells).forEach((cell) => cell.setAttribute('role', cellRole));
}

export function paintSectionExposure(section:HTMLTableSectionElement):void {
  section.setAttribute('role', 'rowgroup');
  const exposed = Array.from(section.rows).some((row) => row.getAttribute('aria-hidden') !== 'true');
  setOrRemove(section, 'aria-hidden', exposed ? null : 'true');
}

export class TreegridSemantics {
  @LazyInject() private readonly wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() private readonly wpTableHierarchies:WorkPackageViewHierarchiesService;

  public readonly injector:Injector = this.table.injector;

  constructor(private readonly table:WorkPackageTable) {}

  public paint():void {
    if (this.table.destroyed) return;
    this.table.ledger.occurrences.forEach((occurrence) => this.paintOccurrence(occurrence));
    paintSectionExposure(this.table.tbody);
  }

  public paintWorkPackage(id:string):void {
    if (this.table.destroyed) return;
    this.table.ledger.byWorkPackageId(id).forEach((occurrence) => this.paintOccurrence(occurrence));
  }

  public paintSelection():void {
    if (this.table.destroyed) return;
    this.table.ledger.occurrences.forEach((occurrence) => this.paintSelected(occurrence));
  }

  private paintOccurrence(occurrence:RenderedOccurrence):void {
    const row = occurrence.element;
    if (!row) return;

    const kind = occurrenceRowKind(occurrence);
    if (kind === 'placeholder') {
      setOrRemove(row, 'aria-hidden', 'true');
      return;
    }

    paintRowRole(row, occurrence.level);
    setOrRemove(row, 'aria-expanded', this.expansionOf(occurrence, kind));
    this.paintSelected(occurrence);
  }

  private paintSelected(occurrence:RenderedOccurrence):void {
    if (occurrence.element && isSelectableOccurrence(occurrence)) {
      occurrence.element.setAttribute('aria-selected', String(this.wpTableSelection.isSelected(occurrence.workPackageId)));
    }
  }

  private expansionOf(occurrence:RenderedOccurrence, kind:Exclude<OccurrenceRowKind, 'placeholder'>):string|null {
    const expanded = kind === 'foreign' ? null : expansionStateOf(this.table, this.wpTableHierarchies, occurrence, kind);
    return expanded === null ? null : String(expanded);
  }
}
