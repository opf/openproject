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
import { WorkPackageTableCellDirective } from './wp-table-cell.directive';
import { LegacyTableActionDirective } from './legacy-table-action.directive';
import { PrimerIconButtonComponent } from 'core-app/shared/components/primer/icon-button.component';
import { internalContextMenuColumn, internalSortColumn } from '../builders/internal-sort-columns';
import { TemplateRow, TemplateRowView } from './template-row';

/**
 * A work package result row. Binds only the row's identity; row state
 * (roles, levels, selection, positions) stays with the row-state painter.
 */
@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'tr[opWpTableRow]',
  imports: [WorkPackageTableCellDirective, LegacyTableActionDirective, PrimerIconButtonComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    tabindex: '-1',
    class: 'wp-table--row wp--row issue',
    '[class]': 'hostClasses()',
    '[attr.data-work-package-id]': 'row().workPackage.id',
    '[attr.data-class-identifier]': 'identifier()',
    '[attr.data-occurrence-key]': 'row().key',
  },
  template: `
    @for (column of view().columns; track column.id) {
      @if (column.id === view().rowHeader) {
        <th scope="row" opWpTableCell [column]="column" [row]="row()" [view]="view()"></th>
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
                <ng-container [opWpLegacyTableAction]="action" />
              }
            }
          </span>
        </td>
      } @else {
        <td opWpTableCell [column]="column" [row]="row()" [view]="view()"></td>
      }
    }
  `,
})
export class WorkPackageTableRowComponent {
  readonly row = input.required<TemplateRow>();
  readonly view = input.required<TemplateRowView>();

  readonly actionsColumnId = internalContextMenuColumn.id;

  readonly sortColumnId = internalSortColumn.id;

  readonly canDrag = computed(() => this.view().canDrag(this.row().workPackage));

  readonly actions = computed(() => this.view().actions(this.row().workPackage));

  readonly identifier = computed(() => `wp-row-${this.row().workPackage.id}`);
  readonly hostClasses = computed(() => [
    this.identifier(),
    `${this.identifier()}-table`,
    ...this.view().rowClasses(this.row().workPackage),
  ]);
}
