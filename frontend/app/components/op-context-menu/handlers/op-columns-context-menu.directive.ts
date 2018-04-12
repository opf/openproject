//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {Directive, ElementRef, Inject, Input} from "@angular/core";
import {I18nToken} from "core-app/angular4-transition-utils";
import {OpContextMenuTrigger} from "core-components/op-context-menu/handlers/op-context-menu-trigger.directive";
import {QueryColumn} from "core-components/wp-query/query-column";
import {WorkPackageTableSortByService} from "core-components/wp-fast-table/state/wp-table-sort-by.service";
import {WorkPackageTableHierarchiesService} from "core-components/wp-fast-table/state/wp-table-hierarchy.service";
import {WorkPackageTableGroupByService} from "core-components/wp-fast-table/state/wp-table-group-by.service";
import {WorkPackageTableColumnsService} from "core-components/wp-fast-table/state/wp-table-columns.service";
import {WorkPackageTable} from 'core-components/wp-fast-table/wp-fast-table';
import {WpTableConfigurationModalComponent} from 'core-components/wp-table/configuration-modal/wp-table-configuration.modal';
import {OpModalService} from 'core-components/op-modals/op-modal.service';

@Directive({
  selector: '[opColumnsContextMenu]'
})
export class OpColumnsContextMenu extends OpContextMenuTrigger {
  @Input('opColumnsContextMenu-column') public column:QueryColumn;
  @Input('opColumnsContextMenu-table') public table:WorkPackageTable;

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly wpTableColumns:WorkPackageTableColumnsService,
              readonly wpTableSortBy:WorkPackageTableSortByService,
              readonly wpTableGroupBy:WorkPackageTableGroupByService,
              readonly wpTableHierarchies:WorkPackageTableHierarchiesService,
              readonly opModalService:OpModalService,
              @Inject(I18nToken) readonly I18n:op.I18n) {

    super(elementRef, opContextMenu);
  }

  protected open(evt:Event) {
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
      items: this.items
    };
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(openerEvent:Event) {
    return {
      my: 'left top',
      at: 'left bottom',
      of: this.$element.find('.generic-table--sort-header-outer')
    };
  }

  protected get afterFocusOn():JQuery {
    return this.$element.find(`#${this.column.id}`);
  }

  private buildItems() {
    let c = this.column;

    this.items = [
      {
        // Sort ascending
        hidden: !this.wpTableSortBy.isSortable(c),
        linkText: this.I18n.t('js.work_packages.query.sort_descending'),
        icon: 'icon-sort-descending',
        onClick: () => {
          this.wpTableSortBy.addDescending(c);
          return true;
        }
      },
      {
        // Sort descending
        hidden: !this.wpTableSortBy.isSortable(c),
        linkText: this.I18n.t('js.work_packages.query.sort_ascending'),
        icon: 'icon-sort-ascending',
        onClick: () => {
          this.wpTableSortBy.addAscending(c);
          return true;
        }
      },
      {
        // Group by
        hidden: !this.wpTableGroupBy.isGroupable(c) || this.wpTableGroupBy.isCurrentlyGroupedBy(c),
        linkText: this.I18n.t('js.work_packages.query.group'),
        icon: 'icon-group-by',
        onClick: () => {
          this.wpTableGroupBy.setBy(c);
          return true;
        }
      },
      {
        // Move left
        hidden: this.wpTableColumns.isFirst(c),
        linkText: this.I18n.t('js.work_packages.query.move_column_left'),
        icon: 'icon-column-left',
        onClick: () => {
          this.wpTableColumns.shift(c, -1);
          return true;
        }
      },
      {
        // Move right
        hidden: this.wpTableColumns.isLast(c),
        linkText: this.I18n.t('js.work_packages.query.move_column_right'),
        icon: 'icon-column-right',
        onClick: () => {
          this.wpTableColumns.shift(c, 1);
          return true;
        }
      },
      {
        // Hide column
        linkText: this.I18n.t('js.work_packages.query.hide_column'),
        icon: 'icon-delete',
        onClick: () => {
          this.wpTableColumns.shift(c, 1);
          let focusColumn = this.wpTableColumns.previous(c) || this.wpTableColumns.next(c);
          this.wpTableColumns.removeColumn(c);

          setTimeout(() => {
            if (focusColumn) {
              jQuery(`#${focusColumn.id}`).focus();
            }
          });
          return true;
        }
      },
      {
        // Insert columns
        linkText: this.I18n.t('js.work_packages.query.insert_columns'),
        icon: 'icon-columns',
        onClick: () => {
          this.opModalService.show<WpTableConfigurationModalComponent>(
            WpTableConfigurationModalComponent,
            { initialTab: 'columns' }
          );
          return true;
        }
      }
    ];
  }
}

