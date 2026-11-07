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

import { Directive, Injector, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
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
import { OpActionMenuService } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.service';
import { FocusPosition, samePosition } from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/keyboard/focus-position';
import { OpContextMenuCloseReason } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

@Directive({
  selector: '[opColumnsContextMenu]',
  standalone: false,
  host: {
    '(pointerdown)': 'rememberPointerToggle()',
  },
})
export class OpColumnsContextMenu extends OpContextMenuTrigger {
  readonly wpTableColumns = inject(WorkPackageViewColumnsService);
  readonly wpTableSortBy = inject(WorkPackageViewSortByService);
  readonly wpTableGroupBy = inject(WorkPackageViewGroupByService);
  readonly wpTableHierarchies = inject(WorkPackageViewHierarchiesService);
  readonly opModalService = inject(OpModalService);
  readonly injector = inject(Injector);
  readonly I18n = inject(I18nService);
  readonly confirmDialog = inject(ConfirmDialogService);

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('opColumnsContextMenu-column') public column:QueryColumn;

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('opColumnsContextMenu-table') public table:WorkPackageTable;

  private readonly actionMenu = inject(OpActionMenuService);
  private wasOpenOnPointerDown = false;
  private origin:FocusPosition|null = null;

  public text = {
    confirmDelete: {
      text: this.I18n.t('js.work_packages.table_configuration.sorting_mode.warning'),
      title: this.I18n.t('js.modals.form_submit.title'),
    },
  };

  rememberPointerToggle():void {
    this.wasOpenOnPointerDown = this.actionMenu.isActive(this);
  }

  protected override toggle(evt:MouseEvent):void {
    if (this.actionMenu.isActive(this)) {
      this.actionMenu.close();
    } else if (evt.detail === 0 || !this.wasOpenOnPointerDown) {
      this.open(evt);
    }
    this.wasOpenOnPointerDown = false;
  }

  override ngOnDestroy():void {
    if (this.actionMenu.isActive(this)) this.actionMenu.close();
    super.ngOnDestroy();
  }

  protected override open(evt:Event) {
    if (!this.table.configuration.columnMenuEnabled) {
      return;
    }
    this.buildItems();
    this.origin = this.table.keyboardNavigation.positionOfCell(this.element);
    this.actionMenu.show(this, evt, this.element.closest('th') ?? this.element);
  }

  public override onClose(focus = true, reason?:OpContextMenuCloseReason):void {
    if (this.origin && (reason === 'escape' || reason === 'action')) {
      this.table.keyboardNavigation.returnFocusFromMenu(this.origin);
      return;
    }

    super.onClose(focus);
  }

  public get locals() {
    return {
      label: this.column.name,
      contextMenuId: 'column-context-menu',
      items: this.items,
    };
  }

  protected get afterFocusOn() {
    return this.element.querySelector<HTMLElement>(`#${this.column.id}, .relations-header--button`)
      ?? this.element.closest<HTMLElement>('th')
      ?? this.element;
  }

  private followColumn(header:HTMLElement|null):void {
    const navigation = this.table.keyboardNavigation;
    const current = navigation.position;
    const position = header && navigation.positionOfCell(header);
    if (!this.origin || !position || !samePosition(current, this.origin)) {
      return;
    }

    navigation.recordPosition(position);
    this.origin = position;
  }

  private sortBy(direction:string):boolean {
    const column = this.column;
    if (!this.wpTableSortBy.isManualSortingMode) {
      this.wpTableSortBy.addSortCriteria(column, direction);
      return true;
    }

    this.actionMenu.close();
    void this.confirmDialog.confirm({ text: this.text.confirmDelete }).then(
      () => this.wpTableSortBy.setAsSingleSortCriteria(column, direction),
      () => undefined,
    );
    return false;
  }

  private buildItems() {
    const c = this.column;

    this.items = [
      {
        hidden: !this.wpTableSortBy.isSortable(c),
        linkText: this.I18n.t('js.work_packages.query.sort_descending'),
        octicon: 'sort-desc',
        onClick: () => this.sortBy(QUERY_SORT_BY_DESC),
      },
      {
        hidden: !this.wpTableSortBy.isSortable(c),
        linkText: this.I18n.t('js.work_packages.query.sort_ascending'),
        octicon: 'sort-asc',
        onClick: () => this.sortBy(QUERY_SORT_BY_ASC),
      },
      {
        hidden: !this.wpTableGroupBy.isGroupable(c) || this.wpTableGroupBy.isCurrentlyGroupedBy(c),
        linkText: this.I18n.t('js.work_packages.query.group'),
        octicon: 'op-group',
        onClick: () => {
          if (this.wpTableHierarchies.isEnabled) {
            this.wpTableHierarchies.setEnabled(false);
          }
          this.wpTableGroupBy.setBy(c);
          return true;
        },
      },
      {
        hidden: this.wpTableColumns.isFirst(c),
        linkText: this.I18n.t('js.work_packages.query.move_column_left'),
        octicon: 'op-columns-left',
        onClick: () => {
          this.wpTableColumns.shift(c, -1);
          this.followColumn(this.element);
          return true;
        },
      },
      {
        hidden: this.wpTableColumns.isLast(c),
        linkText: this.I18n.t('js.work_packages.query.move_column_right'),
        octicon: 'op-columns-right',
        onClick: () => {
          this.wpTableColumns.shift(c, 1);
          this.followColumn(this.element);
          return true;
        },
      },
      {
        linkText: this.I18n.t('js.work_packages.query.hide_column'),
        octicon: 'eye-closed',
        onClick: () => {
          const header = this.element.closest('th');
          const neighbor = this.wpTableColumns.isFirst(c) ? header?.nextElementSibling : header?.previousElementSibling;
          const focusHeader = neighbor instanceof HTMLTableCellElement ? neighbor : null;
          this.actionMenu.close();
          this.wpTableColumns.removeColumn(c);
          this.followColumn(focusHeader);

          if (this.origin) {
            this.table.keyboardNavigation.returnFocusFromMenu(this.origin);
          } else if (focusHeader) {
            setTimeout(() => focusHeader.focus());
          }
          return false;
        },
      },
      {
        linkText: this.I18n.t('js.work_packages.query.insert_columns'),
        octicon: 'columns',
        onClick: () => {
          this.actionMenu.close();
          this.opModalService.show<WpTableConfigurationModalComponent>(
            WpTableConfigurationModalComponent,
            this.injector,
            { initialTab: 'columns' },
          );
          return false;
        },
      },
    ];
  }
}
