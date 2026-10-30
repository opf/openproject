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
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  WorkPackageViewRelationColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageRelationsService } from '../../wp-relations/wp-relations.service';
import { QueryColumn, queryColumnTypes } from '../../wp-query/query-column';
import { tdClassName } from './cell-builder';
import { keyboardNavigationEnabled, navigableCellClassName } from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/keyboard/roving-tabindex';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageTableConfiguration } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';

export const relationCellTdClassName = 'wp-table--relation-cell-td';
export const relationCellIndicatorClassName = 'wp-table--relation-indicator';

export class RelationCellbuilder {
  @LazyInject() states:States;

  @LazyInject() wpRelations:WorkPackageRelationsService;

  @LazyInject() wpTableRelationColumns:WorkPackageViewRelationColumnsService;

  @LazyInject() I18n!:I18nService;

  constructor(public readonly injector:Injector, private readonly configuration?:WorkPackageTableConfiguration) {
  }

  public build(workPackage:WorkPackageResource, column:QueryColumn) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, relationCellTdClassName, column.id);
    td.dataset.columnId = column.id;

    if (keyboardNavigationEnabled(this.configuration)) {
      td.classList.add(navigableCellClassName);
    }

    // Get current expansion and value state
    const expanded = this.wpTableRelationColumns.getExpandFor(workPackage.id!) === column.id;
    const relationState = this.wpRelations.state(workPackage.id!).value;

    let count:number;

    if (column._type === queryColumnTypes.RELATION_CHILD) {
      count = workPackage.children?.length || 0;
    } else {
      const relations = this.wpTableRelationColumns.relationsForColumn(
        workPackage,
        relationState,
        column,
      );
      count = relations.length;
    }

    const indicator = this.renderIndicator(workPackage, column, expanded);
    const badge = this.renderBadge(count);

    if (expanded) {
      td.classList.add('-expanded');
    }

    if (count > 0) {
      td.appendChild(badge);
      td.appendChild(indicator);
    }

    return td;
  }

  private renderIndicator(workPackage:WorkPackageResource, column:QueryColumn, expanded:boolean) {
    if (keyboardNavigationEnabled(this.configuration)) {
      const button = document.createElement('button');
      button.type = 'button';
      button.classList.add(relationCellIndicatorClassName);
      button.setAttribute('tabindex', '-1');
      button.setAttribute('aria-expanded', expanded.toString());
      button.setAttribute('aria-label', this.I18n.t('js.work_packages.table.relations_button', {
        column: column.name,
        work_package: workPackage.formattedId,
      }));

      return button;
    }

    const indicator = document.createElement('span');
    indicator.classList.add(relationCellIndicatorClassName);
    indicator.setAttribute('aria-hidden', 'true');
    indicator.setAttribute('tabindex', '0');

    return indicator;
  }

  private renderBadge(count:number) {
    const badge = document.createElement('span');
    badge.classList.add('wp-table--relation-count');

    badge.textContent = count.toString();
    badge.classList.add('badge');

    return badge;
  }
}
