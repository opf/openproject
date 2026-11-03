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
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  DestroyRef,
  ElementRef,
  effect,
  inject,
  input,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
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
import { combineLatest, filter, merge, Subscription } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { TableUiWork } from 'core-app/features/work-packages/components/wp-fast-table/table-ui-work';
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
export class SortHeaderDirective implements AfterViewInit, ColumnMenuHost {
  private wpTableHierarchies = inject(WorkPackageViewHierarchiesService);
  private wpTableSortBy = inject(WorkPackageViewSortByService);
  private wpTableGroupBy = inject(WorkPackageViewGroupByService);
  private readonly querySpace = inject(IsolatedQuerySpace);
  private readonly wpListService = inject(WorkPackagesListService);
  private wpTableBaseline = inject(WorkPackageViewBaselineService);
  private wpTableRelationColumns = inject(WorkPackageViewRelationColumnsService);
  private elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  private cdRef = inject(ChangeDetectorRef);
  private I18n = inject(I18nService);
  private readonly menuItems = inject(ColumnMenuItems);

  private readonly menu = viewChild(OpActionMenuComponent);

  readonly headerColumn = input.required<QueryColumn>();

  readonly locale = input<string>();

  private readonly destroyRef = inject(DestroyRef);

  private readonly uiWork = new TableUiWork(this.destroyRef);

  private streams = new Subscription();

  readonly table = input<WorkPackageTable>();

  private readonly viewReady = signal(false);

  private initializedTable?:WorkPackageTable;

  readonly items = signal<OpContextMenuItem[]>([]);

  readonly headerCell = signal<HTMLElement|undefined>(undefined);

  private origin:FocusPosition|null = null;

  private menuCell:FocusPosition|null = null;

  private focusHeader:HTMLElement|null = null;

  private menuStreams?:Subscription;

  sortable:boolean;

  directionClass = '';

  public text = {
    openMenu: this.I18n.t('js.label_open_menu'),
    baselineIncompatible: this.I18n.t('js.work_packages.baseline.column_incompatible'),
  };

  isHierarchyColumn:boolean;

  columnType:'plain'|'hierarchy'|'relation'|'sort' = 'plain';

  columnName = '';

  baselineIncompatible = false;

  private currentSortDirection:'asc'|'desc'|null;

  constructor() {
    onDestroySafely(this.destroyRef, () => runCleanup(() => this.menuStreams?.unsubscribe()));
    effect((onCleanup) => {
      const table = this.table();
      if (!this.viewReady()) return;
      this.headerColumn();
      untracked(() => {
        const streams = new Subscription();
        this.streams = streams;
        this.initializedTable = undefined;
        const releaseTable = table && !table.destroyed && !this.destroyRef.destroyed
          ? onDestroySafely(table.destroyRef, () => this.uiWork.cancel())
          : undefined;
        onCleanup(() => {
          this.uiWork.cancel();
          runCleanup(() => streams.unsubscribe());
          runCleanup(() => releaseTable?.());
        });
        this.scheduleInitialize();
      });
    });
  }

  ngAfterViewInit():void {
    this.headerCell.set(this.elementRef.nativeElement.closest('th') ?? undefined);
    this.viewReady.set(true);
  }

  get displayMenu():boolean {
    return !!this.table()?.configuration.columnMenuEnabled;
  }

  get showHierarchyGlyph():boolean {
    return this.isHierarchyColumn
      && !!this.table()?.configuration.hierarchyToggleEnabled
      && this.wpTableHierarchies.isEnabled;
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

  private scheduleInitialize():void {
    const table = this.table();
    if (!this.viewReady() || !table || table.destroyed || this.destroyRef.destroyed || this.initializedTable === table) return;
    this.uiWork.cancel();
    this.uiWork.task(() => {
      if (this.table() !== table || table.destroyed || this.destroyRef.destroyed) return;
      this.initializedTable = table;
      this.initialize(table);
    });
  }

  private initialize(table:WorkPackageTable):void {
    this.columnType = 'plain';
    this.columnName = '';
    this.streams.add(combineLatest([
      this.wpTableSortBy.onReadyWithAvailable(),
      this.wpTableSortBy.live$(),
    ])
      .pipe(
        takeUntilDestroyed(table.destroyRef),
        takeUntilDestroyed(this.destroyRef),
        filter(() => this.table() === table && !table.destroyed && !this.destroyRef.destroyed),
      )
      .subscribe(() => {
        this.currentSortDirection = primarySortDirection(this.wpTableSortBy.current, this.headerColumn());
        this.setActiveColumnClass();

        this.sortable = this.wpTableSortBy.isSortable(this.headerColumn());

        this.directionClass = this.currentSortDirection ?? '';

        this.cdRef.detectChanges();
      }));

    this.isHierarchyColumn = this.headerColumn().id === 'subject';

    if (this.headerColumn().id === 'sortHandle') {
      this.columnType = 'sort';
    }
    if (this.isHierarchyColumn) {
      this.columnType = 'hierarchy';
    } else if (this.wpTableRelationColumns.relationColumnType(this.headerColumn()) === 'toType') {
      this.columnType = 'relation';
      this.columnName = (this.headerColumn() as TypeRelationQueryColumn).type.name;
    } else if (this.wpTableRelationColumns.relationColumnType(this.headerColumn()) === 'ofType') {
      this.columnType = 'relation';
      this.columnName = I18n.t(`js.relation_labels.${(this.headerColumn() as RelationQueryColumn).relationType}`);
    } else if (this.headerColumn()._type === queryColumnTypes.RELATION_CHILD) {
      this.columnType = 'relation';
      this.columnName = this.headerColumn().name;
    }

    if (this.isHierarchyColumn) {
      this.streams.add(this.wpTableHierarchies
        .live$()
        .pipe(
          takeUntilDestroyed(table.destroyRef),
          takeUntilDestroyed(this.destroyRef),
          filter(() => this.table() === table && !table.destroyed && !this.destroyRef.destroyed),
        )
        .subscribe(() => this.cdRef.detectChanges()));
    }

    this.streams.add(this
      .wpTableBaseline
      .live$()
      .pipe(
        takeUntilDestroyed(table.destroyRef),
        takeUntilDestroyed(this.destroyRef),
        filter(() => this.table() === table && !table.destroyed && !this.destroyRef.destroyed),
      )
      .subscribe(() => {
        this.baselineIncompatible = this.wpTableBaseline.isActive() && this.wpTableBaseline.isIncompatibleColumn(this.headerColumn().id);
      }));

    if (this.table() === table && !table.destroyed && !this.destroyRef.destroyed) this.cdRef.detectChanges();
  }

  setActiveColumnClass() {
    const table = this.table();
    if (!table || table.destroyed || this.destroyRef.destroyed) return;
    if (this.currentSortDirection) {
      this.elementRef.nativeElement.classList.add('active-column');
    } else {
      this.elementRef.nativeElement.classList.remove('active-column');
    }
  }
}
