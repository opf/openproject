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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, EventEmitter, Injector, Input, OnInit, Output, ViewEncapsulation, OnDestroy, DestroyRef, inject, signal, computed } from '@angular/core';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  TableEventComponent,
  TableHandlerRegistry,
} from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { combineLatest } from 'rxjs';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { createScrollSync, ScrollSync } from 'core-app/features/work-packages/components/wp-table/wp-table-scroll-sync';
import { WpTableHoverSync } from 'core-app/features/work-packages/components/wp-table/wp-table-hover-sync';
import { WorkPackageTimelineTableController } from 'core-app/features/work-packages/components/wp-table/timeline/container/wp-timeline-container.directive';
import { headerRowKey } from 'core-app/features/work-packages/components/wp-fast-table/row-keys';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import {
  WorkPackageTableConfiguration,
  WorkPackageTableConfigurationObject,
} from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { States } from 'core-app/core/states/states.service';
import { renderedColumns } from 'core-app/features/work-packages/components/wp-fast-table/builders/rendered-columns';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { QUERY_SORT_BY_DESC, QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { primarySortDirection } from 'core-app/features/work-packages/components/wp-table/sort-header/primary-sort-direction';

export interface WorkPackageFocusContext {
  /** Work package that was focused */
  workPackageId:string;
  /** Through what action did the focus happen */
  through:'row-double-click'|'id-click'|'details-icon';
}

interface TableViewState {
  query:QueryResource|undefined;
  results:WorkPackageCollectionResource;
  columns:QueryColumn[];
  sortBy:QuerySortByResource[];
  sumVisible:boolean;
  timelineVisible:boolean;
  manualSortEnabled:boolean;
  baselineEnabled:boolean;
  sortDescription:string;
  trailingColumnRendered:boolean;
  numTableColumns:number;
}

@Component({
  templateUrl: './wp-table.component.html',
  styleUrls: ['./wp-table.component.sass'],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-table',
  standalone: false,
})
export class WorkPackagesTableComponent implements OnInit, TableEventComponent, OnDestroy {
  private readonly destroyRef = inject(DestroyRef);

  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly injector = inject(Injector);
  readonly states = inject(States);
  readonly querySpace = inject(IsolatedQuerySpace);
  readonly I18n = inject(I18nService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly wpTableGroupBy = inject(WorkPackageViewGroupByService);
  readonly wpTableTimeline = inject(WorkPackageViewTimelineService);
  readonly wpTableColumns = inject(WorkPackageViewColumnsService);
  readonly wpTableSortBy = inject(WorkPackageViewSortByService);
  readonly wpTableSums = inject(WorkPackageViewSumService);
  readonly wpTableBaseline = inject(WorkPackageViewBaselineService);

  @Input() projectIdentifier:string;

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('configuration') configurationObject:WorkPackageTableConfigurationObject;

  @Output() itemClicked = new EventEmitter<{ workPackageId:string, double:boolean }>();

  @Output() stateLinkClicked = new EventEmitter<{ workPackageId:string, requestedState:string }>();

  public configuration:WorkPackageTableConfiguration;

  private element:HTMLElement;

  private scrollSync?:ScrollSync;

  private wpTableHoverSync:WpTableHoverSync;

  public tableElement:HTMLElement;

  public workPackageTable:WorkPackageTable;

  public tbody:HTMLTableSectionElement;

  public timeline:HTMLElement;

  public locale:string;

  public text:{
    cancel:string;
    noResults:{ title:string; description:string };
    sorting:string;
    tableName:string;
    actionsHeader:string;
    baselineHeader:string;
    configurationHeader:string;
  };

  private readonly viewStateValue = signal<TableViewState|null>(null);

  readonly viewState = this.viewStateValue.asReadonly();

  public inlineCreateVisible = false;

  readonly numTableColumns = computed(() => this.viewState()?.numTableColumns ?? 0);

  ngOnInit():void {
    this.configuration = new WorkPackageTableConfiguration(this.configurationObject);
    this.element = this.elementRef.nativeElement;

    this.locale = I18n.locale;

    this.text = {
      cancel: this.I18n.t('js.button_cancel'),
      noResults: {
        title: this.I18n.t('js.work_packages.no_results.title'),
        description: this.I18n.t('js.work_packages.no_results.description'),
      },
      sorting: this.I18n.t('js.label_sorting'),
      tableName: this.I18n.t('js.label_work_package_plural'),
      actionsHeader: this.I18n.t('js.work_packages.table.grid_actions_header'),
      baselineHeader: this.I18n.t('js.work_packages.table.grid_baseline_header'),
      configurationHeader: this.I18n.t('js.toolbar.settings.configure_view'),
    };

    const statesCombined = combineLatest({
      results: this.querySpace.results.values$(),
      groupBy: this.wpTableGroupBy.live$(),
      columns: this.wpTableColumns.live$(),
      timelines: this.wpTableTimeline.live$(),
      sortBy: this.wpTableSortBy.live$(),
      sums: this.wpTableSums.live$(),
      baseline: this.wpTableBaseline.live$(),
    });

    statesCombined.pipe(
      takeUntilDestroyed(this.destroyRef),
    ).subscribe(({ results, columns, timelines, sortBy, sums }) => {
      const wasTimelineVisible = this.viewState()?.timelineVisible;
      const manualSortEnabled = this.wpTableSortBy.isManualSortingMode;
      const baselineEnabled = this.wpTableBaseline.isActive();
      const rendered = renderedColumns(this.configuration, baselineEnabled);
      this.viewStateValue.set({
        query: this.querySpace.query.value,
        results,
        columns,
        sortBy,
        sumVisible: sums,
        timelineVisible: timelines.visible,
        manualSortEnabled,
        baselineEnabled,
        sortDescription: this.describeSort(sortBy, manualSortEnabled),
        trailingColumnRendered: rendered.trailing,
        numTableColumns: rendered.count(columns.length),
      });

      if (this.workPackageTable) {
        this.workPackageTable.colspan = this.numTableColumns();
      }

      if (this.scrollSync && wasTimelineVisible !== timelines.visible) {
        this.scrollSync.update(timelines.visible);
      }

      this.renderHeader();
    });

    this.cdRef.detectChanges();
  }

  public ngOnDestroy():void {
    this.workPackageTable?.destroy();
    this.wpTableHoverSync?.deactivate();
    this.scrollSync?.destroy();
  }

  public registerTimeline(controller:WorkPackageTimelineTableController, timelineBody:HTMLElement) {
    if (this.destroyRef.destroyed) {
      return;
    }
    this.workPackageTable?.destroy();

    const tbody = this.element.querySelector<HTMLTableSectionElement>('.work-package--results-tbody')!;
    const scrollContainer = this.element.querySelector<HTMLElement>('.work-package-table--container')!;
    this.workPackageTable = new WorkPackageTable(
      this.injector,
      // Outer container for both table + Timeline
      this.element,
      // Scroll container for the table/timeline
      scrollContainer,
      // Table tbody to insert into
      tbody,
      // Timeline body to insert into
      timelineBody,
      // Timeline controller
      controller,
      // Table configuration
      this.configuration,
    );
    this.workPackageTable.colspan = this.numTableColumns();

    this.tbody = tbody;
    new TableHandlerRegistry(this.injector).attachTo(this);
    controller.workPackageTable = this.workPackageTable;

    // Locate table and timeline elements
    const tableAndTimeline = this.getTableAndTimelineElement();
    this.tableElement = tableAndTimeline[0];
    this.timeline = tableAndTimeline[1];

    // sync hover from table to timeline
    const hover = this.wpTableHoverSync = new WpTableHoverSync(this.element);
    const scroll = this.scrollSync = createScrollSync(this.element);
    onDestroySafely(this.workPackageTable.destroyRef, () => hover.deactivate());
    onDestroySafely(this.workPackageTable.destroyRef, () => scroll.destroy());
    hover.activate();
    scroll.update(this.viewState()?.timelineVisible ?? false);

    this.renderHeader();
  }

  private renderHeader():void {
    if (!this.workPackageTable) {
      this.cdRef.detectChanges();
      return;
    }
    this.workPackageTable.mutate(new Set([headerRowKey]), () => this.cdRef.detectChanges());
  }

  public get isEmbedded() {
    return this.configuration.isEmbedded;
  }

  public get sortDescriptionId():string|null {
    return this.workPackageTable ? `${this.workPackageTable.domId}-sort` : null;
  }

  public ariaSort(column:QueryColumn):'ascending'|'descending'|null {
    switch (primarySortDirection(this.viewState()?.sortBy ?? [], column)) {
      case 'asc':
        return 'ascending';
      case 'desc':
        return 'descending';
      default:
        return null;
    }
  }

  private describeSort(sortBy:QuerySortByResource[], manualSortEnabled:boolean):string {
    if (manualSortEnabled) {
      return this.I18n.t('js.work_packages.table.sorted_manually');
    }

    if (sortBy.length === 0) {
      return '';
    }

    const criteria = sortBy.map(({ column, direction }) => this.I18n.t(
      direction.href === QUERY_SORT_BY_DESC
        ? 'js.work_packages.table.sort_criterion_descending'
        : 'js.work_packages.table.sort_criterion_ascending',
      { column: column.name },
    ));

    return this.I18n.t('js.work_packages.table.sorted_by', {
      criteria: new Intl.ListFormat(this.I18n.locale, { type: 'conjunction' }).format(criteria),
    });
  }

  private getTableAndTimelineElement():[HTMLElement, HTMLElement] {
    const tableSide = this.element.querySelector<HTMLElement>('.work-packages-tabletimeline--table-side');
    const timelineSide = this.element.querySelector<HTMLElement>('.work-packages-tabletimeline--timeline-side');

    if (!tableSide || !timelineSide) {
      throw new Error('invalid state');
    }

    return [tableSide, timelineSide];
  }
}
