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
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  Injector,
  Input,
  NgZone,
  OnInit,
  Output,
  ViewEncapsulation,
} from '@angular/core';
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
import { trackByHref } from 'core-app/shared/helpers/angular/tracking-functions';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { createScrollSync } from 'core-app/features/work-packages/components/wp-table/wp-table-scroll-sync';
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
import { States } from 'core-app/core/states/states.service';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';

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
  selector: 'wp-table',
})
export class WorkPackagesTableComponent extends UntilDestroyedMixin implements OnInit, TableEventComponent {
  @Input() projectIdentifier:string;

  @Input('configuration') configurationObject:WorkPackageTableConfigurationObject;

  @Output() selectionChanged = new EventEmitter<string[]>();

  @Output() itemClicked = new EventEmitter<{ workPackageId:string, double:boolean }>();

  @Output() stateLinkClicked = new EventEmitter<{ workPackageId:string, requestedState:string }>();

  public trackByHref = trackByHref;

  public configuration:WorkPackageTableConfiguration;

  private $element:JQuery;

  private scrollSyncUpdate:(timelineVisible:boolean) => any;

  private wpTableHoverSync:WpTableHoverSync;

  public tableElement:HTMLElement;

  public workPackageTable:WorkPackageTable;

  public tbody:JQuery;

  public query:QueryResource;

  public timeline:HTMLElement;

  public locale:string;

  public text:any;

  public results:WorkPackageCollectionResource;

  public groupBy:QueryGroupByResource|null;

  public columns:QueryColumn[];

  public numTableColumns:number;

  public timelineVisible:boolean;

  public manualSortEnabled:boolean;

  public baselineEnabled:boolean;

  public limitedResults = false;

  // We need to sync certain height difference to the timeline
  // depending on whether inline create or sums rows are being shown
  public inlineCreateVisible = false;

  public sumVisible = false;

  constructor(
    readonly elementRef:ElementRef,
    readonly injector:Injector,
    readonly states:States,
    readonly querySpace:IsolatedQuerySpace,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly zone:NgZone,
    readonly wpTableGroupBy:WorkPackageViewGroupByService,
    readonly wpTableTimeline:WorkPackageViewTimelineService,
    readonly wpTableColumns:WorkPackageViewColumnsService,
    readonly wpTableSortBy:WorkPackageViewSortByService,
    readonly wpTableSums:WorkPackageViewSumService,
    readonly wpTableBaseline:WorkPackageViewBaselineService,
  ) {
    super();
  }

  ngOnInit():void {
    this.configuration = new WorkPackageTableConfiguration(this.configurationObject);
    this.$element = jQuery(this.elementRef.nativeElement);

    // Clear any old table subscribers
    this.querySpace.stopAllSubscriptions.next();

    this.locale = I18n.locale;

    this.text = {
      cancel: I18n.t('js.button_cancel'),
      noResults: {
        title: I18n.t('js.work_packages.no_results.title'),
        description: I18n.t('js.work_packages.no_results.description'),
      },
      limitedResults: (count:number, total:number) => I18n.t('js.work_packages.limited_results', { count, total }),
      tableSummary: I18n.t('js.work_packages.table.summary'),
      tableSummaryHints: [
        I18n.t('js.work_packages.table.text_inline_edit'),
        I18n.t('js.work_packages.table.text_select_hint'),
        I18n.t('js.work_packages.table.text_sort_hint'),
      ].join(' '),
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
    ).subscribe(([results, groupBy, columns, timelines, sort, sums]) => {
      this.query = this.querySpace.query.value!;

      this.results = results;
      this.sumVisible = sums;

      this.groupBy = groupBy;
      this.columns = columns;

      this.timelineVisible = timelines.visible;

      this.manualSortEnabled = this.wpTableSortBy.isManualSortingMode;
      this.baselineEnabled = this.wpTableBaseline.isActive();
      this.limitedResults = this.manualSortEnabled && results.total > results.count;

      // Total columns = all available columns + id + context menu
      this.numTableColumns = this.columns.length + 2;

      if (this.manualSortEnabled) {
        this.numTableColumns += 1;
      }

      if (this.baselineEnabled) {
        this.numTableColumns += 1;
      }

      if (this.workPackageTable) {
        this.workPackageTable.colspan = this.numTableColumns;
      }

      if (this.scrollSyncUpdate && this.timelineVisible !== timelines.visible) {
        this.scrollSyncUpdate(timelines.visible);
      }

      this.cdRef.detectChanges();
    });

    this.cdRef.detectChanges();
  }

  public ngOnDestroy():void {
    super.ngOnDestroy();
    this.wpTableHoverSync.deactivate();
  }

  public registerTimeline(controller:WorkPackageTimelineTableController, timelineBody:HTMLElement) {
    const tbody = this.$element.find('.work-package--results-tbody');
    const scrollContainer = this.$element.find('.work-package-table--container')[0];
    this.workPackageTable = new WorkPackageTable(
      this.injector,
      // Outer container for both table + Timeline
      this.$element[0],
      // Scroll container for the table/timeline
      scrollContainer,
      // Table tbody to insert into
      tbody[0],
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
    this.wpTableHoverSync = new WpTableHoverSync(this.$element);
    this.wpTableHoverSync.activate();

    // sync scroll from table to timeline
    this.scrollSyncUpdate = createScrollSync(this.$element);
    this.scrollSyncUpdate(this.timelineVisible);

    this.cdRef.detectChanges();
  }

  public get isEmbedded() {
    return this.configuration.isEmbedded;
  }

  private getTableAndTimelineElement():[HTMLElement, HTMLElement] {
    const $tableSide = this.$element.find('.work-packages-tabletimeline--table-side');
    const $timelineSide = this.$element.find('.work-packages-tabletimeline--timeline-side');

    if ($timelineSide.length === 0 || $tableSide.length === 0) {
      throw new Error('invalid state');
    }

    return [$tableSide[0], $timelineSide[0]];
  }
}
