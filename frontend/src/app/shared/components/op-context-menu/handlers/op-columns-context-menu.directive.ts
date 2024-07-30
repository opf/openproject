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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  Directive, ElementRef, Injector, Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WpTableConfigurationModalComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';
import { QUERY_SORT_BY_ASC, QUERY_SORT_BY_DESC } from 'core-app/features/hal/resources/query-sort-by-resource';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';

@Directive({
  selector: '[opColumnsContextMenu]',
})
export class OpColumnsContextMenu extends OpContextMenuTrigger {
  @Input('opColumnsContextMenu-column') public column:QueryColumn;

  @Input('opColumnsContextMenu-table') public table:WorkPackageTable;

  public text = {
    confirmDelete: {
      text: this.I18n.t('js.work_packages.table_configuration.sorting_mode.warning'),
      title: this.I18n.t('js.modals.form_submit.title'),
    },
  };

  constructor(readonly elementRef:ElementRef,
    readonly opContextMenu:OPContextMenuService,
    readonly wpTableColumns:WorkPackageViewColumnsService,
    readonly wpTableSortBy:WorkPackageViewSortByService,
    readonly wpTableGroupBy:WorkPackageViewGroupByService,
    readonly wpTableHierarchies:WorkPackageViewHierarchiesService,
    readonly opModalService:OpModalService,
    readonly injector:Injector,
    readonly I18n:I18nService,
    readonly confirmDialog:ConfirmDialogService) {
    super(elementRef, opContextMenu);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    if (!this.table.configuration.columnMenuEnabled) {
      return;
    }
    this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  public get locals() {
    return {
      showAnchorRight: this.column && this.column.id !== 'id',
      contextMenuId: 'column-context-menu',
      items: this.items,
    };
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(evt:JQuery.TriggeredEvent) {
    const additionalPositionArgs = {
      of: this.$element.find('.generic-table--sort-header-outer'),
    };

    const position = super.positionArgs(evt);
    _.assign(position, additionalPositionArgs);

    return position;
  }

  protected get afterFocusOn():JQuery {
    return this.$element.find(`#${this.column.id}`);
  }

  private buildItems() {
    const c = this.column;

    this.items = [
      {
        // Sort ascending
        hidden: !this.wpTableSortBy.isSortable(c),
        linkText: this.I18n.t('js.work_packages.query.sort_descending'),
        icon: 'icon-sort-descending',
        onClick: (evt:any) => {
          if (this.wpTableSortBy.isManualSortingMode) {
            this.confirmDialog.confirm({
              text: this.text.confirmDelete,
            }).then(() => {
              this.wpTableSortBy.setAsSingleSortCriteria(c, QUERY_SORT_BY_DESC);
              return true;
            });
            return false;
          }
          this.wpTableSortBy.addSortCriteria(c, QUERY_SORT_BY_DESC);
          return true;
        },
      },
      {
        // Sort descending
        hidden: !this.wpTableSortBy.isSortable(c),
        linkText: this.I18n.t('js.work_packages.query.sort_ascending'),
        icon: 'icon-sort-ascending',
        onClick: (evt:any) => {
          if (this.wpTableSortBy.isManualSortingMode) {
            this.confirmDialog.confirm({
              text: this.text.confirmDelete,
            }).then(() => {
              this.wpTableSortBy.setAsSingleSortCriteria(c, QUERY_SORT_BY_ASC);
              return true;
            });
            return false;
          }
          this.wpTableSortBy.addSortCriteria(c, QUERY_SORT_BY_ASC);
          return true;
        },
      },
      {
        // Group by
        hidden: !this.wpTableGroupBy.isGroupable(c) || this.wpTableGroupBy.isCurrentlyGroupedBy(c),
        linkText: this.I18n.t('js.work_packages.query.group'),
        icon: 'icon-group-by',
        onClick: () => {
          if (this.wpTableHierarchies.isEnabled) {
            this.wpTableHierarchies.setEnabled(false);
          }
          this.wpTableGroupBy.setBy(c);
          return true;
        },
      },
      {
        // Move left
        hidden: this.wpTableColumns.isFirst(c),
        linkText: this.I18n.t('js.work_packages.query.move_column_left'),
        icon: 'icon-column-left',
        onClick: () => {
          this.wpTableColumns.shift(c, -1);
          return true;
        },
      },
      {
        // Move right
        hidden: this.wpTableColumns.isLast(c),
        linkText: this.I18n.t('js.work_packages.query.move_column_right'),
        icon: 'icon-column-right',
        onClick: () => {
          this.wpTableColumns.shift(c, 1);
          return true;
        },
      },
      {
        // Hide column
        linkText: this.I18n.t('js.work_packages.query.hide_column'),
        icon: 'icon-delete',
        onClick: () => {
          const focusColumn = this.wpTableColumns.previous(c) || this.wpTableColumns.next(c);
          this.wpTableColumns.removeColumn(c);

          setTimeout(() => {
            if (focusColumn) {
              jQuery(`#${focusColumn.id}`).focus();
            }
          });
          return true;
        },
      },
      {
        // Insert columns
        linkText: this.I18n.t('js.work_packages.query.insert_columns'),
        icon: 'icon-columns',
        onClick: () => {
          this.opModalService.show<WpTableConfigurationModalComponent>(
            WpTableConfigurationModalComponent,
            this.injector,
            { initialTab: 'columns' },
          );
          return true;
        },
      },
    ];
  }
}
