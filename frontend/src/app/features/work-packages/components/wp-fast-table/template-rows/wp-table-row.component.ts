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

import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { WorkPackageTableCellContentDirective, WorkPackageTableCellDirective } from './wp-table-cell.directive';
import { WorkPackageTableActionComponent } from './wp-table-action.component';
import { PrimerIconButtonComponent } from 'core-app/shared/components/primer/icon-button.component';
import { internalContextMenuColumn, internalSortColumn } from '../builders/internal-sort-columns';
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
  imports: [WorkPackageTableCellDirective, WorkPackageTableCellContentDirective, WorkPackageTableActionComponent, PrimerIconButtonComponent],
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
  template: `
    @let entry = row();
    @switch (entry.kind) {
      @case ('groupHeader') {
        <td [attr.colspan]="view().columns.length" class="-no-highlighting wp-table--navigable-cell" tabindex="-1">
          <div class="expander icon-context" [class.icon-plus]="entry.collapsed" [class.icon-minus2]="!entry.collapsed">
            <span class="sr-only">{{ entry.collapsed ? entry.expandLabel : entry.collapseLabel }}</span>
          </div>
          <div class="group--value" data-test-selector="op-group--value">
            @if (entry.leadingIcon; as icon) {
              <span [opWpTableCellContent]="icon"></span>
            }
            {{ entry.name }} <span class="count">({{ entry.count }})</span>
          </div>
        </td>
      }
      @case ('sums') {
        @for (cell of entry.cells; track cell.columnId) {
          <td [class.wp-table--navigable-cell]="cell.navigable"
            [attr.aria-describedby]="cell.describedBy"
            [opWpTableCellContent]="cell.content"></td>
        }
      }
      @case ('workPackage') {
        @for (column of view().columns; track column.id) {
          @if (column.id === view().rowHeader) {
            <th scope="row" opWpTableCell [column]="column" [row]="entry" [view]="view()"></th>
          } @else if (column.id === sortColumnId && canDrag() !== null) {
            <td
              class="wp-table--cell-td __internal-sorthandle"
              [class.wp-table--sort-td]="canDrag()"
              [class.hide-when-print]="canDrag()"
            >
              @if (canDrag()) {
                <span class="wp-table--drag-and-drop-handle icon-drag-handle"></span>
              }
            </td>
          } @else if (column.id === actionsColumnId && actions()) {
            <td class="wp-table--cell-td wp-table--context-menu-td __internal-contextMenu hide-when-print wp-table--navigable-cell">
              <span class="wp-table--context-menu-span">
                @for (action of actions(); track action.identifier) {
                  @if (action.identifier === 'open-context-menu-action') {
                    <primer-icon-button
                      icon="kebab-horizontal"
                      scheme="invisible"
                      button-class="wp-table-context-menu-link"
                      [label]="view().contextMenuLabel"
                      [tabindex]="-1"
                    />
                  } @else {
                    <span [opWpTableAction]="action"></span>
                  }
                }
              </span>
            </td>
          } @else {
            <td opWpTableCell [column]="column" [row]="entry" [view]="view()"></td>
          }
        }
      }
    }
  `,
})
export class WorkPackageTableRowComponent {
  readonly row = input.required<TemplateRow>();
  readonly view = input.required<TemplateRowView>();

  readonly actionsColumnId = internalContextMenuColumn.id;

  readonly sortColumnId = internalSortColumn.id;

  readonly workPackageRow = computed(() => {
    const row = this.row();
    return row.kind === 'workPackage' ? row : null;
  });

  readonly groupHeader = computed(() => {
    const row = this.row();
    return row.kind === 'groupHeader' ? row : null;
  });

  readonly canDrag = computed(() => {
    const row = this.workPackageRow();
    return row ? this.view().canDrag(row.workPackage) : null;
  });

  readonly actions = computed(() => {
    const row = this.workPackageRow();
    return row ? this.view().actions(row.workPackage) : null;
  });

  readonly expandable = computed(() => {
    const row = this.workPackageRow();
    return row && this.view().rowHeader === 'subject' && row.additionalClasses.includes(hierarchyRootClass(row.workPackage.id!));
  });

  readonly hostClasses = computed(() => {
    const row = this.row();
    const { key, classIdentifier, additionalClasses } = row;
    if (row.kind === 'groupHeader') return [rowGroupClassName, classIdentifier];
    if (row.kind === 'sums') return ['wp-table--sums-row', 'wp-table--row', classIdentifier, ...additionalClasses];

    const classes = ['wp-table--row', 'wp--row', 'issue', classIdentifier, `${classIdentifier}-table`,
      ...additionalClasses, ...this.view().rowClasses(row.workPackage)];
    if (key === ancestorOccurrenceKey(row.workPackage.id!)) {
      classes.push(`wp-row-${row.workPackage.id}`, `wp-row-${row.workPackage.id}-table`);
    }
    return classes;
  });
}
