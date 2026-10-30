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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, EventEmitter, Injector, Input, OnInit, Output, ViewEncapsulation, OnDestroy, DestroyRef, inject } from '@angular/core';
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
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import {
  WorkPackageTableConfiguration,
  WorkPackageTableConfigurationObject,
} from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { States } from 'core-app/core/states/states.service';
import { renderedColumns } from 'core-app/features/work-packages/components/wp-fast-table/builders/rendered-columns';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { QUERY_SORT_BY_DESC } from 'core-app/features/hal/resources/query-sort-by-resource';
import { primarySortDirection } from 'core-app/features/work-packages/components/wp-table/sort-header/primary-sort-direction';

export interface WorkPackageFocusContext {
  /** Work package that was focused */
  workPackageId:string;
  /** Through what action did the focus happen */
  through:'row-double-click'|'id-click'|'details-icon';
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
export class WorkPackagesTableComponent extends UntilDestroyedMixin implements OnInit, TableEventComponent, OnDestroy {
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

  public query:QueryResource;

  public timeline:HTMLElement;

  public locale:string;

  public text:{
    cancel:string;
    noResults:{ title:string; description:string };
    limitedResults:(count:number, total:number) => string;
    sorting:string;
    tableName:string;
    tableSummary:string;
    tableSummaryHints:string;
    actionsHeader:string;
    baselineHeader:string;
    configurationHeader:string;
  };

  public results:WorkPackageCollectionResource;

  public groupBy:QueryGroupByResource|null;

  public columns:QueryColumn[];

  public numTableColumns:number;

  public trailingColumnRendered = true;

  public timelineVisible:boolean;

  public manualSortEnabled:boolean;

  public baselineEnabled:boolean;

  public limitedResults = false;

  public sortDescription = '';

  // We need to sync certain height difference to the timeline
  // depending on whether inline create or sums rows are being shown
  public inlineCreateVisible = false;

  public sumVisible = false;

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
      limitedResults: (count:number, total:number) => this.I18n.t('js.work_packages.limited_results', { count, total }),
      sorting: this.I18n.t('js.label_sorting'),
      tableName: this.I18n.t('js.label_work_package_plural'),
      tableSummary: this.I18n.t('js.work_packages.table.summary'),
      tableSummaryHints: [
        this.I18n.t('js.work_packages.table.text_inline_edit'),
        this.I18n.t('js.work_packages.table.text_select_hint'),
        this.I18n.t('js.work_packages.table.text_sort_hint'),
      ].join(' '),
      actionsHeader: this.I18n.t('js.work_packages.table.grid_actions_header'),
      baselineHeader: this.I18n.t('js.work_packages.table.grid_baseline_header'),
      configurationHeader: this.I18n.t('js.toolbar.settings.configure_view'),
    };

    const statesCombined = combineLatest([
      this.querySpace.results.values$(),
      this.wpTableGroupBy.live$(),
      this.wpTableColumns.live$(),
      this.wpTableTimeline.live$(),
      this.wpTableSortBy.live$(),
      this.wpTableSums.live$(),
      this.wpTableBaseline.live$(),
    ]);

    statesCombined.pipe(
      this.untilDestroyed(),
    ).subscribe(([results, groupBy, columns, timelines, _sort, sums]) => {
      this.query = this.querySpace.query.value!;

      this.results = results;
      this.sumVisible = sums;

      this.groupBy = groupBy;
      this.columns = columns;

      const wasTimelineVisible = this.timelineVisible;
      this.timelineVisible = timelines.visible;

      this.manualSortEnabled = this.wpTableSortBy.isManualSortingMode;
      this.baselineEnabled = this.wpTableBaseline.isActive();
      this.limitedResults = this.manualSortEnabled && results.total > results.count;

      if (this.configuration.keyboardNavigationEnabled) {
        this.sortDescription = this.describeSort();
        const rendered = renderedColumns(this.configuration, this.baselineEnabled);
        this.trailingColumnRendered = rendered.trailing;
        this.numTableColumns = rendered.count(this.columns.length);
      } else {
        // Total columns = all available columns + id + context menu
        this.numTableColumns = this.columns.length + 2;

        if (this.manualSortEnabled) {
          this.numTableColumns += 1;
        }

        if (this.baselineEnabled) {
          this.numTableColumns += 1;
        }
      }

      if (this.workPackageTable) {
        this.workPackageTable.colspan = this.numTableColumns;
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
    super.ngOnDestroy();
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
    this.workPackageTable.colspan = this.numTableColumns;

    this.tbody = tbody;
    controller.workPackageTable = this.workPackageTable;
    new TableHandlerRegistry(this.injector).attachTo(this);

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
    scroll.update(this.timelineVisible);

    this.renderHeader();
  }

  private renderHeader():void {
    this.cdRef.detectChanges();
    this.workPackageTable?.rowPositions?.paint();
  }

  public get isEmbedded() {
    return this.configuration.isEmbedded;
  }

  public get sortDescriptionId():string|null {
    return this.workPackageTable ? `${this.workPackageTable.domId}-sort` : null;
  }

  public ariaSort(column:QueryColumn):'ascending'|'descending'|null {
    if (!this.configuration.keyboardNavigationEnabled) {
      return null;
    }

    switch (primarySortDirection(this.wpTableSortBy.current, column)) {
      case 'asc':
        return 'ascending';
      case 'desc':
        return 'descending';
      default:
        return null;
    }
  }

  private describeSort():string {
    const sortBy = this.wpTableSortBy.current;

    if (this.wpTableSortBy.isManualSortingMode) {
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
