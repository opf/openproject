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

import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { combineLatest, map } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  QueryColumn, queryColumnTypes,
  RelationQueryColumn,
  TypeRelationQueryColumn,
} from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { primarySortDirection } from './primary-sort-direction';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'sortHeader',
  templateUrl: './sort-header.directive.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
// eslint-disable-next-line @angular-eslint/component-class-suffix
export class SortHeaderDirective {
  private readonly wpTableHierarchies = inject(WorkPackageViewHierarchiesService);
  private readonly wpTableSortBy = inject(WorkPackageViewSortByService);
  private readonly wpTableGroupBy = inject(WorkPackageViewGroupByService);
  private readonly wpTableBaseline = inject(WorkPackageViewBaselineService);
  private readonly wpTableRelationColumns = inject(WorkPackageViewRelationColumnsService);
  private readonly I18n = inject(I18nService);

  readonly headerColumn = input.required<QueryColumn>();

  readonly locale = input<string>();

  readonly table = input<WorkPackageTable>();

  readonly text = {
    openMenu: this.I18n.t('js.label_open_menu'),
    baselineIncompatible: this.I18n.t('js.work_packages.baseline.column_incompatible'),
  };

  private readonly sortState = toSignal(combineLatest([
    this.wpTableSortBy.onReadyWithAvailable(),
    this.wpTableSortBy.live$(),
  ]).pipe(map(() => ({}))));

  private readonly hierarchyEnabled = toSignal(
    this.wpTableHierarchies.live$().pipe(map(() => this.wpTableHierarchies.isEnabled)),
    { initialValue: this.wpTableHierarchies.isEnabled },
  );

  private readonly baselineActive = toSignal(
    this.wpTableBaseline.live$().pipe(map(() => this.wpTableBaseline.isActive())),
    { initialValue: false },
  );

  readonly displayDropdownIcon = computed(() => this.table()?.configuration.columnMenuEnabled ?? false);

  readonly displayHierarchyIcon = computed(() => this.table()?.configuration.hierarchyToggleEnabled ?? false);

  readonly sortable = computed(() => !!this.sortState() && this.wpTableSortBy.isSortable(this.headerColumn()));

  readonly sortDirection = computed(() => {
    this.sortState();
    return primarySortDirection(this.wpTableSortBy.current, this.headerColumn());
  });

  readonly columnType = computed<'plain'|'hierarchy'|'relation'|'sort'>(() => {
    const column = this.headerColumn();
    if (column.id === 'subject') return 'hierarchy';
    if (this.wpTableRelationColumns.relationColumnType(column) || column._type === queryColumnTypes.RELATION_CHILD) return 'relation';
    if (column.id === 'sortHandle') return 'sort';
    return 'plain';
  });

  readonly columnName = computed(() => {
    const column = this.headerColumn();
    switch (this.wpTableRelationColumns.relationColumnType(column)) {
      case 'toType':
        return (column as TypeRelationQueryColumn).type.name;
      case 'ofType':
        return this.I18n.t(`js.relation_labels.${(column as RelationQueryColumn).relationType}`);
      default:
        return column._type === queryColumnTypes.RELATION_CHILD ? column.name : '';
    }
  });

  readonly hierarchyIcon = computed(() => (this.hierarchyEnabled() ? 'icon-hierarchy' : 'icon-no-hierarchy'));

  readonly hierarchyToggleTitle = computed(() => this.I18n.t(
    this.hierarchyEnabled() ? 'js.work_packages.hierarchy.hide' : 'js.work_packages.hierarchy.show',
  ));

  readonly baselineIncompatible = computed(() => this.baselineActive()
    && this.wpTableBaseline.isIncompatibleColumn(this.headerColumn().id));

  toggleHierarchy(evt:Event) {
    if (this.wpTableHierarchies.toggleState()) {
      this.wpTableGroupBy.disable();
    }

    evt.stopPropagation();
    return false;
  }
}
