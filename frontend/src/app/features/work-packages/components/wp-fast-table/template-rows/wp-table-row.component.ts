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
import { TemplateRow, TemplateRowView } from './template-row';

/**
 * A work package result row. Binds only the row's identity; row state
 * (roles, levels, selection, positions) stays with the row-state painter.
 */
@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'tr[opWpTableRow]',
  imports: [WorkPackageTableCellDirective],
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
      } @else {
        <td opWpTableCell [column]="column" [row]="row()" [view]="view()"></td>
      }
    }
  `,
})
export class WorkPackageTableRowComponent {
  readonly row = input.required<TemplateRow>();
  readonly view = input.required<TemplateRowView>();

  readonly identifier = computed(() => `wp-row-${this.row().workPackage.id}`);
  readonly hostClasses = computed(() => [
    this.identifier(),
    `${this.identifier()}-table`,
    ...this.view().rowClasses(this.row().workPackage),
  ]);
}
