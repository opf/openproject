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

import { inject, Injectable, Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QUERY_SORT_BY_ASC, QUERY_SORT_BY_DESC, QuerySortDirection } from 'core-app/features/hal/resources/query-sort-by-resource';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WpTableConfigurationModalComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { primarySortDirection } from './primary-sort-direction';

/** What a column menu's actions need from the header that owns the menu. */
export interface ColumnMenuHost {
  /** Hides the header's own menu synchronously. */
  close():void;
  /** Re-records the header-owned focus origin on the given header, or drops it. */
  followColumn(header:HTMLElement|null):void;
  /** Moves focus to the recorded origin through the table, which outlives a removed header. */
  returnFocus():void;
}

/** Builds the items of one column header's menu. Provided by the sort header, one per header. */
@Injectable()
export class ColumnMenuItems {
  private readonly wpTableColumns = inject(WorkPackageViewColumnsService);
  private readonly wpTableSortBy = inject(WorkPackageViewSortByService);
  private readonly wpTableGroupBy = inject(WorkPackageViewGroupByService);
  private readonly wpTableHierarchies = inject(WorkPackageViewHierarchiesService);
  private readonly opModalService = inject(OpModalService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  private readonly injector = inject(Injector);
  private readonly I18n = inject(I18nService);

  private readonly text = {
    confirmDelete: {
      text: this.I18n.t('js.work_packages.table_configuration.sorting_mode.warning'),
      title: this.I18n.t('js.modals.form_submit.title'),
    },
  };

  build(column:QueryColumn, table:WorkPackageTable, header:HTMLElement, host:ColumnMenuHost):OpContextMenuItem[] {
    const sortable = this.wpTableSortBy.isSortable(column);
    const sortDirection = primarySortDirection(this.wpTableSortBy.current, column);

    return [
      {
        hidden: !sortable,
        linkText: this.I18n.t('js.work_packages.query.sort_descending'),
        octicon: 'sort-desc',
        checked: sortDirection === 'desc',
        radio: true,
        onClick: () => this.sortUnlessSorted(column, QUERY_SORT_BY_DESC, sortDirection === 'desc', host),
      },
      {
        hidden: !sortable,
        linkText: this.I18n.t('js.work_packages.query.sort_ascending'),
        octicon: 'sort-asc',
        checked: sortDirection === 'asc',
        radio: true,
        onClick: () => this.sortUnlessSorted(column, QUERY_SORT_BY_ASC, sortDirection === 'asc', host),
      },
      { divider: true },
      {
        hidden: !this.wpTableGroupBy.isGroupable(column),
        linkText: this.I18n.t('js.work_packages.query.group_by_column', { column: column.name }),
        octicon: 'op-group',
        checked: this.wpTableGroupBy.isCurrentlyGroupedBy(column),
        onClick: () => {
          if (this.wpTableGroupBy.isCurrentlyGroupedBy(column)) {
            this.wpTableGroupBy.disable();
            return true;
          }
          if (this.wpTableHierarchies.isEnabled) {
            this.wpTableHierarchies.setEnabled(false);
          }
          this.wpTableGroupBy.setBy(column);
          return true;
        },
      },
      {
        hidden: column.id !== 'subject' || !table.configuration.hierarchyToggleEnabled,
        linkText: this.I18n.t('js.toolbar.settings.display_hierarchy'),
        octicon: 'op-hierarchy',
        checked: this.wpTableHierarchies.isEnabled,
        disabled: this.wpTableGroupBy.isEnabled,
        onClick: () => {
          this.wpTableHierarchies.setEnabled(!this.wpTableHierarchies.isEnabled);
          return true;
        },
      },
      { divider: true },
      {
        hidden: this.wpTableColumns.isFirst(column),
        linkText: this.I18n.t('js.work_packages.query.move_column_left'),
        octicon: 'op-columns-left',
        onClick: () => {
          host.close();
          this.wpTableColumns.shift(column, -1);
          host.followColumn(header);
          host.returnFocus();
          return false;
        },
      },
      {
        hidden: this.wpTableColumns.isLast(column),
        linkText: this.I18n.t('js.work_packages.query.move_column_right'),
        octicon: 'op-columns-right',
        onClick: () => {
          host.close();
          this.wpTableColumns.shift(column, 1);
          host.followColumn(header);
          host.returnFocus();
          return false;
        },
      },
      {
        linkText: this.I18n.t('js.work_packages.query.add_columns'),
        octicon: 'columns',
        onClick: () => {
          host.close();
          this.opModalService.show<WpTableConfigurationModalComponent>(
            WpTableConfigurationModalComponent,
            this.injector,
            { initialTab: 'columns' },
          );
          return false;
        },
      },
      {
        linkText: this.I18n.t('js.work_packages.query.remove_column'),
        octicon: 'x-circle',
        onClick: () => {
          const th = header.closest('th') ?? header;
          const neighbor = this.wpTableColumns.isFirst(column) ? th.nextElementSibling : th.previousElementSibling;
          host.close();
          this.wpTableColumns.removeColumn(column);
          host.followColumn(neighbor instanceof HTMLTableCellElement ? neighbor : null);
          host.returnFocus();
          return false;
        },
      },
    ];
  }

  private sortUnlessSorted(column:QueryColumn, direction:QuerySortDirection, sorted:boolean, host:ColumnMenuHost):boolean {
    return sorted || this.sortBy(column, direction, host);
  }

  private sortBy(column:QueryColumn, direction:QuerySortDirection, host:ColumnMenuHost):boolean {
    if (!this.wpTableSortBy.isManualSortingMode) {
      this.wpTableSortBy.addSortCriteria(column, direction);
      return true;
    }

    host.close();
    void this.confirmDialog.confirm({ text: this.text.confirmDelete }).then(
      () => this.wpTableSortBy.setAsSingleSortCriteria(column, direction),
      () => undefined,
    );
    return false;
  }
}
