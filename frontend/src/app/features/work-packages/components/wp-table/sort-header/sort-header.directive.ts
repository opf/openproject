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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  computed,
  DestroyRef,
  ElementRef,
  inject,
  input,
  signal,
  viewChild,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { map, merge, Subscription } from 'rxjs';
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
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { onDestroySafely, runCleanup } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import { OpContextMenuCloseReason, OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { FocusPosition, samePosition } from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/keyboard/focus-position';
import { primarySortDirection } from './primary-sort-direction';
import { ColumnMenuHost, ColumnMenuItems } from './column-menu-items';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'sortHeader',
  templateUrl: './sort-header.directive.html',
  providers: [ColumnMenuItems],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
// eslint-disable-next-line @angular-eslint/component-class-suffix
export class SortHeaderDirective implements ColumnMenuHost {
  private readonly wpTableHierarchies = inject(WorkPackageViewHierarchiesService);
  private readonly wpTableSortBy = inject(WorkPackageViewSortByService);
  private readonly wpTableGroupBy = inject(WorkPackageViewGroupByService);
  private readonly querySpace = inject(IsolatedQuerySpace);
  private readonly wpListService = inject(WorkPackagesListService);
  private readonly wpTableBaseline = inject(WorkPackageViewBaselineService);
  private readonly wpTableRelationColumns = inject(WorkPackageViewRelationColumnsService);
  private readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly cdRef = inject(ChangeDetectorRef);
  private readonly I18n = inject(I18nService);
  private readonly menuItems = inject(ColumnMenuItems);
  private readonly destroyRef = inject(DestroyRef);

  private readonly menu = viewChild(OpActionMenuComponent);

  readonly headerColumn = input.required<QueryColumn>();

  readonly locale = input<string>();

  readonly table = input<WorkPackageTable>();

  readonly items = signal<OpContextMenuItem[]>([]);

  readonly headerCell = this.elementRef.nativeElement.closest('th') ?? undefined;

  private origin:FocusPosition|null = null;

  private menuCell:FocusPosition|null = null;

  private focusHeader:HTMLElement|null = null;

  private menuStreams?:Subscription;

  readonly text = {
    openMenu: this.I18n.t('js.label_open_menu'),
    baselineIncompatible: this.I18n.t('js.work_packages.baseline.column_incompatible'),
  };

  private readonly sortState = toSignal(this.wpTableSortBy.live$().pipe(map(() => ({}))));

  private readonly hierarchyEnabled = toSignal(
    this.wpTableHierarchies.live$().pipe(map(() => this.wpTableHierarchies.isEnabled)),
    { initialValue: this.wpTableHierarchies.isEnabled },
  );

  private readonly baselineActive = toSignal(
    this.wpTableBaseline.live$().pipe(map(() => this.wpTableBaseline.isActive())),
    { initialValue: false },
  );

  readonly displayMenu = computed(() => this.table()?.configuration.columnMenuEnabled ?? false);

  readonly directionClass = computed(() => {
    this.sortState();
    return primarySortDirection(this.wpTableSortBy.current, this.headerColumn()) ?? '';
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

  readonly showHierarchyGlyph = computed(() => this.columnType() === 'hierarchy'
    && (this.table()?.configuration.hierarchyToggleEnabled ?? false)
    && this.hierarchyEnabled());

  readonly baselineIncompatible = computed(() => this.baselineActive()
    && this.wpTableBaseline.isIncompatibleColumn(this.headerColumn().id));

  constructor() {
    onDestroySafely(this.destroyRef, () => runCleanup(() => this.menuStreams?.unsubscribe()));
  }

  onMenuOpening():void {
    const table = this.table();
    if (!table) return;

    const header = this.elementRef.nativeElement;
    this.menuCell = table.keyboardNavigation.positionOfCell(header);
    this.origin = this.menuCell;
    this.focusHeader = header.closest('th');
    this.items.set(this.buildItems(table, header));
    this.cdRef.detectChanges();
    this.menuStreams = merge(
      this.wpTableSortBy.live$(),
      this.wpTableGroupBy.live$(),
      this.wpTableHierarchies.live$(),
      this.querySpace.available.sortBy.values$(),
      this.querySpace.available.groupBy.values$(),
    ).subscribe(() => this.refreshItems(table, header));
    if (!this.querySpace.queryForm.hasValue()) {
      this.wpListService.conditionallyLoadForm().catch(() => undefined);
    }
  }

  onMenuClosed(reason:OpContextMenuCloseReason):void {
    this.menuStreams?.unsubscribe();
    this.menuStreams = undefined;
    this.items.set([]);
    const table = this.table();
    if (table && this.origin && (reason === 'escape' || reason === 'action')) {
      table.keyboardNavigation.returnFocusFromMenu(this.origin, this.menuCell ?? this.origin);
    }
  }

  close():void {
    this.menu()?.close();
  }

  private buildItems(table:WorkPackageTable, header:HTMLElement):OpContextMenuItem[] {
    return this.menuItems.build(this.headerColumn(), table, header, this);
  }

  private refreshItems(table:WorkPackageTable, header:HTMLElement):void {
    const items = this.buildItems(table, header);
    const shape = (list:OpContextMenuItem[]) => list.map((item) => [item.linkText, item.hidden, item.disabled, item.checked]);
    if (JSON.stringify(shape(items)) === JSON.stringify(shape(this.items()))) {
      return;
    }

    this.items.set(items);
    this.cdRef.detectChanges();
  }

  followColumn(header:HTMLElement|null):void {
    this.focusHeader = header;
    const navigation = this.table()?.keyboardNavigation;
    if (!navigation) return;

    const current = navigation.position;
    const position = header && navigation.positionOfCell(header);
    if (!this.origin || !position || !samePosition(current, this.origin)) {
      return;
    }

    navigation.recordPosition(position);
    navigation.focusPosition(position);
    this.origin = position;
  }

  returnFocus():void {
    const table = this.table();
    if (table && this.origin) {
      table.keyboardNavigation.returnFocusFromMenu(this.origin, this.menuCell ?? this.origin);
      return;
    }

    const header = this.focusHeader;
    setTimeout(() => header?.focus());
  }
}
