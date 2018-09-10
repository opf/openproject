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

import {Component, OnDestroy, OnInit} from '@angular/core';
import {StateService, TransitionService} from '@uirouter/core';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {auditTime, distinctUntilChanged, filter, take, withLatestFrom} from 'rxjs/operators';
import {debugLog} from '../../../helpers/debug_output';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {States} from '../../states.service';
import {WorkPackageQueryStateService} from '../../wp-fast-table/state/wp-table-base.service';
import {WorkPackageTableColumnsService} from '../../wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableFiltersService} from '../../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableGroupByService} from '../../wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTablePaginationService} from '../../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableRelationColumnsService} from '../../wp-fast-table/state/wp-table-relation-columns.service';
import {WorkPackageTableSortByService} from '../../wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableSumService} from '../../wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableTimelineService} from '../../wp-fast-table/state/wp-table-timeline.service';
import {WorkPackagesListChecksumService} from '../../wp-list/wp-list-checksum.service';
import {WorkPackagesListService} from '../../wp-list/wp-list.service';
import {WorkPackageTableRefreshService} from '../../wp-table/wp-table-refresh-request.service';
import {WorkPackageTableHierarchiesService} from './../../wp-fast-table/state/wp-table-hierarchy.service';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";

@Component({
  selector: 'wp-list',
  templateUrl: './wp.list.component.html'
})
export class WorkPackagesListComponent implements OnInit, OnDestroy {

  projectIdentifier = this.$state.params['projectPath'] || null;

  text = {
    'jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.label_pagination'),
    'button_settings': this.I18n.t('js.button_settings')
  };

  tableInformationLoaded = false;
  selectedTitle?:string;
  staticTitle?:string;
  titleEditingEnabled:boolean;

  currentQuery:QueryResource;


  constructor(readonly states:States,
              readonly tableState:TableState,
              readonly authorisationService:AuthorisationService,
              readonly wpTableRefresh:WorkPackageTableRefreshService,
              readonly wpTableColumns:WorkPackageTableColumnsService,
              readonly wpTableHighlighting:WorkPackageTableHighlightingService,
              readonly wpTableSortBy:WorkPackageTableSortByService,
              readonly wpTableGroupBy:WorkPackageTableGroupByService,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpTableSum:WorkPackageTableSumService,
              readonly wpTableTimeline:WorkPackageTableTimelineService,
              readonly wpTableHierarchies:WorkPackageTableHierarchiesService,
              readonly wpTablePagination:WorkPackageTablePaginationService,
              readonly wpListService:WorkPackagesListService,
              readonly wpListChecksumService:WorkPackagesListChecksumService,
              readonly loadingIndicator:LoadingIndicatorService,
              readonly $transitions:TransitionService,
              readonly $state:StateService,
              readonly I18n:I18nService,
              readonly wpStaticQueries:WorkPackageStaticQueriesService) {

  }

  ngOnInit() {
    const loadingRequired = this.wpListChecksumService.isUninitialized();

    // Listen to changes on the query state objects
    this.setupQueryObservers();

    //  Require initial loading of the list if not yet done
    if (loadingRequired) {
      this.wpTableRefresh.clear('Impending query loading.');
      this.wpListService.loadCurrentQueryFromParams(this.projectIdentifier);
    }

    // Listen for refresh changes
    this.setupRefreshObserver();

    // Listen for param changes
    this.$transitions.onSuccess({}, (transition):any => {
      let options = transition.options();

      // Avoid performing any changes when we're going to reload
      if (options.reload || (options.custom && options.custom.notify === false)) {
        return true;
      }

      const params = transition.params('to');
      let newChecksum = this.wpListService.getCurrentQueryProps(params);
      let newId = params.query_id && parseInt(params.query_id);

      this.wpListChecksumService
        .executeIfOutdated(newId,
          newChecksum,
          () => this.wpListService.loadCurrentQueryFromParams(this.projectIdentifier));
    });
  }

  ngOnDestroy():void {
    this.wpTableRefresh.clear('Table controller scope destroyed.');
  }

  public allowed(model:string, permission:string) {
    return this.authorisationService.can(model, permission);
  }

  public setAnchorToNextElement() {
    // Skip to next when visible, otherwise skip to previous
    const selectors = '#pagination--next-link, #pagination--prev-link, #pagination-empty-text';
    const visibleLink = jQuery(selectors)
      .not(':hidden')
      .first();

    if (visibleLink.length) {
      visibleLink.focus();
    }
  }

  private setupQueryObservers() {
    this.tableState.tableRendering.onQueryUpdated.values$()
      .pipe(
        take(1)
      )
      .subscribe(() => this.tableInformationLoaded = true);

    // Update the title whenever the query changes
    this.states.query.resource.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((query) => {
      this.updateTitle(query);
      this.currentQuery = query;
    });

    this.tableState.ready.fireOnStateChange(this.wpTablePagination.state,
      'Query loaded').values$().pipe(
      untilComponentDestroyed(this),
      withLatestFrom(this.states.query.resource.values$())
    ).subscribe(([pagination, query]) => {
      if (this.wpListChecksumService.isQueryOutdated(query, pagination)) {
        this.wpListChecksumService.update(query, pagination);
        this.updateResultsVisibly();
      }
    });

    this.setupChangeObserver(this.wpTableFilters, true);
    this.setupChangeObserver(this.wpTableGroupBy);
    this.setupChangeObserver(this.wpTableSortBy);
    this.setupChangeObserver(this.wpTableSum);
    this.setupChangeObserver(this.wpTableTimeline);
    this.setupChangeObserver(this.wpTableHierarchies);
    this.setupChangeObserver(this.wpTableColumns);
    this.setupChangeObserver(this.wpTableHighlighting);
  }

  setupChangeObserver(service:WorkPackageQueryStateService, firstPage:boolean = false) {
    const queryState = this.states.query.resource;

    this.tableState.ready.fireOnStateChange(service.state, 'Query loaded').values$().pipe(
      untilComponentDestroyed(this),
      filter(() => queryState.hasValue() && service.hasChanged(queryState.value!))
    ).subscribe(() => {
      const newQuery = queryState.value!;
      const triggerUpdate = service.applyToQuery(newQuery);
      this.states.query.resource.putValue(newQuery);

      // Update the current checksum
      this.wpListChecksumService.updateIfDifferent(newQuery, this.wpTablePagination.current);

      // Update the page, if the change requires it
      if (triggerUpdate) {
        this.wpTableRefresh.request('Query updated by user', true, firstPage);
      }
    });
  }

  /**
   * Setup the listener for members of the table to request a refresh of the entire table
   * through the refresh service.
   */
  setupRefreshObserver() {
    this.wpTableRefresh.state.values$('Refresh listener in wp-list.controller').pipe(
      untilComponentDestroyed(this),
      auditTime(20)
    ).subscribe(([refreshVisibly, firstPage]) => {
      if (refreshVisibly) {
        debugLog('Refreshing work package results visibly.');
        this.updateResultsVisibly(firstPage);
      } else {
        debugLog('Refreshing work package results in the background.');
        this.updateResults();
      }
    });
  }

  updateResults():Promise<WorkPackageCollectionResource> {
    return this.wpListService.reloadCurrentResultsList();
  }

  updateToFirstResultsPage():Promise<WorkPackageCollectionResource> {
    return this.wpListService.loadCurrentResultsListFirstPage();
  }

  updateResultsVisibly(firstPage:boolean = false) {
    if (firstPage) {
      this.loadingIndicator.table.promise = this.updateToFirstResultsPage();
    } else {
      this.loadingIndicator.table.promise = this.updateResults();
    }
  }

  updateTitle(query:QueryResource) {
    if (query.id) {
      this.selectedTitle = query.name;
      this.titleEditingEnabled = true;
    } else {
      this.selectedTitle =  this.wpStaticQueries.getStaticName(query);
      this.titleEditingEnabled = false;
    }
  }
}
