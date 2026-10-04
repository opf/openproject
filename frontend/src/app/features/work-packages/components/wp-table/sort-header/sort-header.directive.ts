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

import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, DestroyRef, ElementRef, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  QueryColumn, queryColumnTypes,
  RelationQueryColumn,
  TypeRelationQueryColumn,
} from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import {
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC, QuerySortByDirection,
} from 'core-app/features/hal/resources/query-sort-by-resource';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { combineLatest, filter, Subscription } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { TableUiWork } from 'core-app/features/work-packages/components/wp-fast-table/table-ui-work';
import { onDestroySafely, runCleanup } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'sortHeader',
  templateUrl: './sort-header.directive.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
// eslint-disable-next-line @angular-eslint/component-class-suffix
export class SortHeaderDirective implements AfterViewInit {
  private wpTableHierarchies = inject(WorkPackageViewHierarchiesService);
  private wpTableSortBy = inject(WorkPackageViewSortByService);
  private wpTableGroupBy = inject(WorkPackageViewGroupByService);
  private wpTableBaseline = inject(WorkPackageViewBaselineService);
  private wpTableRelationColumns = inject(WorkPackageViewRelationColumnsService);
  private elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  private cdRef = inject(ChangeDetectorRef);
  private I18n = inject(I18nService);

  @Input() headerColumn:QueryColumn;

  @Input() locale:string;

  private readonly destroyRef = inject(DestroyRef);

  private readonly uiWork = new TableUiWork(this.destroyRef);

  private streams = new Subscription();

  private releaseTableCallback?:() => void;

  private currentTable:WorkPackageTable;

  private viewReady = false;

  private initializedTable?:WorkPackageTable;

  @Input()
  set table(table:WorkPackageTable) {
    this.uiWork.cancel();
    runCleanup(() => this.streams.unsubscribe());
    this.streams = new Subscription();
    runCleanup(() => this.releaseTableCallback?.());
    this.releaseTableCallback = undefined;
    this.currentTable = table;
    this.initializedTable = undefined;
    if (table && !table.destroyed && !this.destroyRef.destroyed) {
      this.releaseTableCallback = onDestroySafely(table.destroyRef, () => this.uiWork.cancel());
    }
    this.scheduleInitialize();
  }

  get table():WorkPackageTable {
    return this.currentTable;
  }

  sortable:boolean;

  directionClass:string;

  public text = {
    toggleHierarchy: this.I18n.t('js.work_packages.hierarchy.show'),
    openMenu: this.I18n.t('js.label_open_menu'),
    baselineIncompatible: this.I18n.t('js.work_packages.baseline.column_incompatible'),
  };

  isHierarchyColumn:boolean;

  columnType:'hierarchy'|'relation'|'sort';

  columnName:string;

  hierarchyIcon:string;

  isHierarchyDisabled:boolean;

  baselineIncompatible = false;

  private currentSortDirection:QuerySortByDirection|null;

  constructor() {
    onDestroySafely(this.destroyRef, () => {
      this.uiWork.cancel();
      runCleanup(() => this.streams.unsubscribe());
      runCleanup(() => this.releaseTableCallback?.());
      this.releaseTableCallback = undefined;
    });
  }

  ngAfterViewInit():void {
    this.viewReady = true;
    this.scheduleInitialize();
  }

  private scheduleInitialize():void {
    const table = this.table;
    if (!this.viewReady || !table || table.destroyed || this.destroyRef.destroyed || this.initializedTable === table) return;
    this.uiWork.cancel();
    this.uiWork.task(() => {
      if (this.table !== table || table.destroyed || this.destroyRef.destroyed) return;
      this.initializedTable = table;
      this.initialize(table);
    });
  }

  private initialize(table:WorkPackageTable):void {
    this.streams.add(combineLatest([
      this.wpTableSortBy.onReadyWithAvailable(),
      this.wpTableSortBy.live$(),
    ])
      .pipe(
        takeUntilDestroyed(table.destroyRef),
        takeUntilDestroyed(this.destroyRef),
        filter(() => this.table === table && !table.destroyed && !this.destroyRef.destroyed),
      )
      .subscribe(() => {
        const latestSortElement = this.wpTableSortBy.current[0];

        if (this.headerColumn.href !== latestSortElement?.column.href) {
          this.currentSortDirection = null;
        } else {
          this.currentSortDirection = latestSortElement.direction;
        }
        this.setActiveColumnClass();

        this.sortable = this.wpTableSortBy.isSortable(this.headerColumn);

        this.directionClass = this.getDirectionClass();

        this.cdRef.detectChanges();
      }));

    // Place the hierarchy icon left to the subject column
    this.isHierarchyColumn = this.headerColumn.id === 'subject';

    if (this.headerColumn.id === 'sortHandle') {
      this.columnType = 'sort';
    }
    if (this.isHierarchyColumn) {
      this.columnType = 'hierarchy';
    } else if (this.wpTableRelationColumns.relationColumnType(this.headerColumn) === 'toType') {
      this.columnType = 'relation';
      this.columnName = (this.headerColumn as TypeRelationQueryColumn).type.name;
    } else if (this.wpTableRelationColumns.relationColumnType(this.headerColumn) === 'ofType') {
      this.columnType = 'relation';
      this.columnName = I18n.t(`js.relation_labels.${(this.headerColumn as RelationQueryColumn).relationType}`);
    } else if (this.headerColumn._type === queryColumnTypes.RELATION_CHILD) {
      this.columnType = 'relation';
      this.columnName = this.headerColumn.name;
    }

    if (this.isHierarchyColumn) {
      this.hierarchyIcon = 'icon-hierarchy';
      this.isHierarchyDisabled = this.wpTableGroupBy.isEnabled;

      // Disable hierarchy mode when group by is active
      this.streams.add(this.wpTableGroupBy
        .live$()
        .pipe(
          takeUntilDestroyed(table.destroyRef),
          takeUntilDestroyed(this.destroyRef),
          filter(() => this.table === table && !table.destroyed && !this.destroyRef.destroyed),
        )
        .subscribe(() => {
          this.isHierarchyDisabled = this.wpTableGroupBy.isEnabled;
          this.cdRef.detectChanges();
        }));

      // Update hierarchy icon when updated elsewhere
      this.streams.add(this.wpTableHierarchies
        .live$()
        .pipe(
          takeUntilDestroyed(table.destroyRef),
          takeUntilDestroyed(this.destroyRef),
          filter(() => this.table === table && !table.destroyed && !this.destroyRef.destroyed),
        )
        .subscribe(() => {
          this.setHierarchyIcon();
          this.cdRef.detectChanges();
        }));

      // Set initial icon
      this.setHierarchyIcon();
    }

    this.streams.add(this
      .wpTableBaseline
      .live$()
      .pipe(
        takeUntilDestroyed(table.destroyRef),
        takeUntilDestroyed(this.destroyRef),
        filter(() => this.table === table && !table.destroyed && !this.destroyRef.destroyed),
      )
      .subscribe(() => {
        this.baselineIncompatible = this.wpTableBaseline.isActive() && this.wpTableBaseline.isIncompatibleColumn(this.headerColumn.id);
      }));

    if (this.table === table && !table.destroyed && !this.destroyRef.destroyed) this.cdRef.detectChanges();
  }

  public get displayDropdownIcon() {
    return this.table?.configuration.columnMenuEnabled;
  }

  public get displayHierarchyIcon() {
    return this.table?.configuration.hierarchyToggleEnabled;
  }

  toggleHierarchy(evt:Event) {
    if (this.wpTableHierarchies.toggleState()) {
      this.wpTableGroupBy.disable();
    }

    this.setHierarchyIcon();

    evt.stopPropagation();
    return false;
  }

  setHierarchyIcon() {
    if (this.wpTableHierarchies.isEnabled) {
      this.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.hide');
      this.hierarchyIcon = 'icon-hierarchy';
    } else {
      this.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.show');
      this.hierarchyIcon = 'icon-no-hierarchy';
    }
  }

  private getDirectionClass():string {
    if (!this.currentSortDirection) {
      return '';
    }

    switch (this.currentSortDirection.href) {
      case QUERY_SORT_BY_ASC:
        return 'asc';
      case QUERY_SORT_BY_DESC:
        return 'desc';
      default:
        return '';
    }
  }

  setActiveColumnClass() {
    if (!this.table || this.table.destroyed || this.destroyRef.destroyed) return;
    if (this.currentSortDirection) {
      this.elementRef.nativeElement.classList.add('active-column');
    } else {
      this.elementRef.nativeElement.classList.remove('active-column');
    }
  }
}
