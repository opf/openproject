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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { States } from 'core-app/core/states/states.service';
import { commonRowClassName, SingleRowBuilder, tableRowClassName } from '../rows/single-row-builder';
import { tdClassName } from '../cell-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { isRelationColumn, QueryColumn } from '../../../wp-query/query-column';

export function relationGroupClass(workPackageId:string) {
  return `__relations-expanded-from-${workPackageId}`;
}

export function relationIdentifier(targetId:string, workPackageId:string) {
  return `wp-relation-row-${workPackageId}-to-${targetId}`;
}

export const relationCellClassName = 'wp-table--relation-cell-td';

export class RelationRowBuilder extends SingleRowBuilder {
  @LazyInject() public states:States;

  @LazyInject() public I18n:I18nService;

  constructor(
public readonly injector:Injector,
              protected workPackageTable:WorkPackageTable,
) {
    super(injector, workPackageTable);
  }

  /**
   * For additional relation rows, we don't want to render an expandable relation cell,
   * but instead we render the relation label.
   * @param workPackage
   * @param column
   * @return {any}
   */
  public buildCell(workPackage:WorkPackageResource, column:QueryColumn):HTMLTableCellElement|null {
    // handle relation types
    if (isRelationColumn(column)) {
      return this.emptyRelationCell(column);
    }

    return super.buildCell(workPackage, column);
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmptyRelationRow(from:WorkPackageResource, to:WorkPackageResource):[HTMLTableRowElement, WorkPackageResource] {
    // Let the primary row builder build the row
    const row = this.createEmptyRelationRow(from, to);
    const [tr] = super.buildEmptyRow(to, row);

    return [tr, to];
  }

  /**
   * Create an empty unattached row element for the given work package
   * @param workPackage
   * @returns {any}
   */
  public createEmptyRelationRow(from:WorkPackageResource, to:WorkPackageResource) {
    const identifier = this.relationClassIdentifier(from, to);
    const tr = document.createElement('tr');
    tr.dataset.workPackageId = to.id!;
    tr.dataset.classIdentifier = identifier;

    tr.classList.add(
      commonRowClassName,
tableRowClassName,
'issue',
'wp-table--relations-additional-row',
identifier,
`${identifier}-table`,
relationGroupClass(from.id!),
    );

    return tr;
  }

  public relationClassIdentifier(from:WorkPackageResource, to:WorkPackageResource) {
    return relationIdentifier(to.id!, from.id!);
  }

  /**
   *
   * @param row
   * @param typeLabel
   * @param columnId
   */
  public appendRelationLabel(
    row:HTMLTableRowElement,
    typeLabel:string,
    columnId:string,
  ):void {
    const relationLabel = document.createElement('span');
    relationLabel.classList.add('relation-row--type-label', 'badge');
    relationLabel.textContent = typeLabel;

    row.querySelector(`.${relationCellClassName}`)!.innerHTML = '';
    row.querySelector(`.${relationCellClassName}.${columnId}`)!.append(relationLabel);
  }

  protected emptyRelationCell(column:QueryColumn) {
    const cell = document.createElement('td');
    cell.classList.add(relationCellClassName, tdClassName, column.id);

    return cell;
  }
}
