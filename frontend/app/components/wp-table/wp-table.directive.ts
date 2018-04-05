// -- copyright
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
// ++

import {Component, ElementRef, Inject, Injector, Input, OnDestroy, OnInit} from '@angular/core';
import {columnsModalToken, I18nToken} from 'core-app/angular4-transition-utils';
import {QueryGroupByResource} from 'core-components/api/api-v3/hal-resources/query-group-by-resource.service';
import {QueryResource} from 'core-components/api/api-v3/hal-resources/query-resource.service';
import {TableHandlerRegistry} from 'core-components/wp-fast-table/handlers/table-handler-registry';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {combineLatest} from 'rxjs/observable/combineLatest';
import {debugLog} from '../../helpers/debug_output';
import {States} from '../states.service';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableGroupByService} from '../wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableTimelineService} from '../wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageTable} from '../wp-fast-table/wp-fast-table';
import {WorkPackageTimelineTableController} from './timeline/container/wp-timeline-container.directive';
import {WpTableHoverSync} from './wp-table-hover-sync';
import {createScrollSync} from './wp-table-scroll-sync';
import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {
  WorkPackageTableConfiguration,
  WorkPackageTableConfigurationObject
} from 'core-app/components/wp-table/wp-table-configuration';
import {QueryColumn} from 'core-components/wp-query/query-column';
import {OpModalService} from 'core-components/op-modals/op-modal.service';


@Component({
  template: require('!!raw-loader!./wp-table.directive.html'),
  selector: 'wp-table',
})
export class WorkPackagesTableController implements OnInit, OnDestroy {

  @Input() projectIdentifier:string;
  @Input('configuration') configurationObject:WorkPackageTableConfigurationObject;
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

  public rowcount:number;

  public groupBy:QueryGroupByResource | undefined;

  public columns:QueryColumn[];

  public numTableColumns:number;

  public timelineVisible:boolean;

  constructor(private elementRef:ElementRef,
              public injector:Injector,
              private states:States,
              readonly tableState:TableState,
              readonly opModalService:OpModalService,
              private opContextMenu:OPContextMenuService,
              @Inject(I18nToken) private I18n:op.I18n,
              private wpTableGroupBy:WorkPackageTableGroupByService,
              private wpTableTimeline:WorkPackageTableTimelineService,
              private wpTableColumns:WorkPackageTableColumnsService) {
  }

  ngOnInit():void {
    this.configuration = new WorkPackageTableConfiguration(this.configurationObject);
    this.$element = jQuery(this.elementRef.nativeElement);
    this.scrollSyncUpdate = createScrollSync(this.$element);

    // Clear any old table subscribers
    this.tableState.stopAllSubscriptions.next();

    this.locale = I18n.locale;

    this.text = {
      cancel: I18n.t('js.button_cancel'),
      noResults: {
        title: I18n.t('js.work_packages.no_results.title'),
        description: I18n.t('js.work_packages.no_results.description')
      },
      faultyQuery: {
        title: I18n.t('js.work_packages.faulty_query.title'),
        description: I18n.t('js.work_packages.faulty_query.description')
      },
      addColumns: I18n.t('js.label_add_columns'),
      tableSummary: I18n.t('js.work_packages.table.summary'),
      tableSummaryHints: [
        I18n.t('js.work_packages.table.text_inline_edit'),
        I18n.t('js.work_packages.table.text_select_hint'),
        I18n.t('js.work_packages.table.text_sort_hint')
      ].join(' ')
    };

    let statesCombined = combineLatest(
      this.tableState.results.values$(),
      this.wpTableGroupBy.state.values$(),
      this.wpTableColumns.state.values$(),
      this.wpTableTimeline.state.values$());

    statesCombined.pipe(
      untilComponentDestroyed(this)
    ).subscribe(([results, groupBy, columns, timelines]) => {
      this.query = this.tableState.query.value!;
      this.rowcount = results.count;

      this.groupBy = groupBy.current;
      this.columns = columns.current;
      // Total columns = all available columns + id + checkbox
      this.numTableColumns = this.columns.length + 2;

      if (this.timelineVisible !== timelines.current) {
        this.scrollSyncUpdate(timelines.current);
      }
      this.timelineVisible = timelines.current;
    });

    // Locate table and timeline elements
    const tableAndTimeline = this.getTableAndTimelineElement();
    this.tableElement = tableAndTimeline[0];
    this.timeline = tableAndTimeline[1];

    // sync hover from table to timeline
    this.wpTableHoverSync = new WpTableHoverSync(this.$element);
    this.wpTableHoverSync.activate();
  }

  public ngOnDestroy():void {
    this.wpTableHoverSync.deactivate();
  }

  public registerTimeline(controller:WorkPackageTimelineTableController, body:HTMLElement) {
    let t0 = performance.now();

    const tbody = this.$element.find('.work-package--results-tbody');
    this.workPackageTable = new WorkPackageTable(this.injector, this.$element[0], tbody[0], body, controller, this.configuration);
    this.tbody = tbody;
    controller.workPackageTable = this.workPackageTable;
    new TableHandlerRegistry(this.injector).attachTo(this.workPackageTable);

    let t1 = performance.now();
    debugLog('Render took ', t1 - t0, ' milliseconds.');
  }

  public openColumnsModal() {
    this.opContextMenu.close();
    this.opModalService.show(ColumnsModalComponent);
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
