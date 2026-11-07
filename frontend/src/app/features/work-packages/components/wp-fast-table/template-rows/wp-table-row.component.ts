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

import { WorkPackageTableTextCellDirective } from './wp-table-text-cell.directive';
import { ChangeDetectionStrategy, Component, computed, ElementRef, inject, input, linkedSignal } from '@angular/core';
import { WorkPackageTableCellContentDirective, WorkPackageTableCellDirective } from './wp-table-cell.directive';
import { WorkPackageTableActionComponent } from './wp-table-action.component';
import { WorkPackageTableIdCellDirective } from './wp-table-id-cell.directive';
import { PrimerIconButtonComponent } from 'core-app/shared/components/primer/icon-button.component';
import { isRelationColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { internalContextMenuColumn, internalSortColumn } from '../builders/internal-sort-columns';
import { TextCellPresentation } from './text-cell-presentation';
import { TemplateRow, TemplateRowView } from './template-row';
import { hierarchyRootClass } from '../helpers/wp-table-hierarchy-helpers';
import { rowGroupClassName } from '../builders/modes/grouped/grouped-classes.constants';
import { ancestorOccurrenceKey } from '../rendered-occurrence-ledger';

/**
 * A work package result row. Binds only the row's identity; row state
 * (roles, levels, selection, positions) stays with the row-state painter.
 */
@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'tr[opWpTableRow]',
  imports: [
    WorkPackageTableTextCellDirective,
    WorkPackageTableCellDirective,
    WorkPackageTableCellContentDirective,
    WorkPackageTableActionComponent,
    WorkPackageTableIdCellDirective,
    PrimerIconButtonComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    tabindex: '-1',
    '[class]': 'hostClasses()',
    '[attr.data-work-package-id]': 'workPackageRow()?.workPackage?.id ?? null',
    '[attr.id]': 'groupHeader() ? "wp-table-rowgroup-" + groupHeader()?.index : null',
    '[attr.data-group-index]': 'groupHeader()?.index ?? null',
    '[attr.data-group-identifier]': 'groupHeader()?.identifier ?? null',
    '[attr.data-class-identifier]': 'row().classIdentifier',
    '[attr.data-occurrence-key]': 'row().key',
    '[attr.data-expandable]': 'expandable() ? "" : null',
  },
  templateUrl: './wp-table-row.component.html',
})
export class WorkPackageTableRowComponent {
  readonly row = input.required<TemplateRow>();
  readonly view = input.required<TemplateRowView>();

  readonly actionsColumnId = internalContextMenuColumn.id;

  readonly sortColumnId = internalSortColumn.id;

  readonly isRelationColumn = isRelationColumn;

  readonly workPackageRow = computed(() => {
    const row = this.row();
    return row.kind === 'workPackage' ? row : null;
  });

  private readonly element = inject<ElementRef<HTMLTableRowElement>>(ElementRef);

  readonly textCells = linkedSignal({
    source: () => ({ row: this.workPackageRow(), view: this.view() }),
    computation: ({ row, view }, previous):Map<string, TextCellPresentation|null> => new Map(view.columns.map((column) => {
      const cell = Array.from(this.element.nativeElement.cells).find((entry) => entry.classList.contains(column.id));
      if (row && cell && previous?.value.has(column.id) && view.isEditing(row.workPackage, column, cell)) {
        return [column.id, previous.value.get(column.id) ?? null];
      }
      return [column.id, row ? view.textCell(row, column) : null];
    })),
  });

  readonly groupHeader = computed(() => {
    const row = this.row();
    return row.kind === 'groupHeader' ? row : null;
  });

  readonly canDrag = computed(() => {
    const row = this.workPackageRow();
    return row && !row.relation ? this.view().canDrag(row.workPackage) : null;
  });

  readonly actions = computed(() => {
    const row = this.workPackageRow();
    return row ? this.view().actions(row.workPackage) : null;
  });

  readonly expandable = computed(() => {
    const row = this.workPackageRow();
    return row && !row.relation && this.view().rowHeader === 'subject' && row.additionalClasses.includes(hierarchyRootClass(row.workPackage.id!));
  });

  readonly hostClasses = computed(() => {
    const row = this.row();
    const { key, classIdentifier, additionalClasses } = row;
    if (row.kind === 'groupHeader') return [rowGroupClassName, classIdentifier];
    if (row.kind === 'sums') return ['wp-table--sums-row', 'wp-table--row', classIdentifier, ...additionalClasses];

    const classes = ['wp-table--row', 'wp--row', 'issue', classIdentifier, `${classIdentifier}-table`, ...additionalClasses];
    if (!row.relation) classes.push(...this.view().rowClasses(row.workPackage));
    if (key === ancestorOccurrenceKey(row.workPackage.id!)) {
      classes.push(`wp-row-${row.workPackage.id}`, `wp-row-${row.workPackage.id}-table`);
    }
    return classes;
  });
}
