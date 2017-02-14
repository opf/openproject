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

import {QueryResource} from '../api/api-v3/hal-resources/query-resource.service';
import {QueryFormResource} from '../api/api-v3/hal-resources/query-form-resource.service';
import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';
import {QueryDmService, PaginationObject} from '../api/api-v3/hal-resource-dms/query-dm.service';
import {QueryFormDmService} from '../api/api-v3/hal-resource-dms/query-form-dm.service';
import {States} from '../states.service';
import {SchemaResource} from '../api/api-v3/hal-resources/schema-resource.service';
import {ErrorResource} from '../api/api-v3/hal-resources/error-resource.service';
import {WorkPackageCollectionResource} from '../api/api-v3/hal-resources/wp-collection-resource.service';
import {QuerySchemaResourceInterface} from '../api/api-v3/hal-resources/query-schema-resource.service';
import {QueryFilterResource} from '../api/api-v3/hal-resources/query-filter-resource.service';
import {QuerySortByResource} from '../api/api-v3/hal-resources/query-sort-by-resource.service';
import {QueryFilterInstanceSchemaResource} from '../api/api-v3/hal-resources/query-filter-instance-schema-resource.service';
import {QueryFilterInstanceResource} from '../api/api-v3/hal-resources/query-filter-instance-resource.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableSortByService} from '../wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableGroupByService} from '../wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableFiltersService} from '../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableSumService} from '../wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTablePaginationService} from '../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackagesListInvalidQueryService} from './wp-list-invalid-query.service.ts';

export class WorkPackagesListService {
  constructor(protected NotificationsService:any,
              protected UrlParamsHelper:any,
              protected AuthorisationService:any,
              protected $q:ng.IQService,
              protected $state:any,
              protected QueryDm:QueryDmService,
              protected QueryFormDm:QueryFormDmService,
              protected states:States,
              protected wpCacheService:WorkPackageCacheService,
              protected wpTableColumns:WorkPackageTableColumnsService,
              protected wpTableSortBy:WorkPackageTableSortByService,
              protected wpTableGroupBy:WorkPackageTableGroupByService,
              protected wpTableFilters:WorkPackageTableFiltersService,
              protected wpTableSum:WorkPackageTableSumService,
              protected wpTablePagination:WorkPackageTablePaginationService,
              protected wpListInvalidQueryService:WorkPackagesListInvalidQueryService,
              protected I18n:op.I18n,
              protected queryMenuItemFactory:any) {}

  /**
   * Load a query.
   * The query is either a persisted query, identified by the query_id parameter, or the default query. Both will be modified by the parameters in the query_props parameter.
   */
  public fromQueryParams(queryParams:any, projectIdentifier ?:string):ng.IPromise<QueryResource> {
    var queryData = this.UrlParamsHelper.buildV3GetQueryFromJsonParams(queryParams.query_props);

    this.clearDependentStates();

    var wpListPromise = this.QueryDm.find(queryData, queryParams.query_id, projectIdentifier);

    let promise = this.updateStatesFromQueryOnPromise(wpListPromise);

    promise
      .catch(error => {
        var queryProps = this.UrlParamsHelper.buildV3GetQueryFromJsonParams(queryParams.query_props);

        return this.handleQueryLoadingError(error, queryProps, queryParams.query_id, projectIdentifier);
      });

    return this.conditionallyLoadForm(promise);
  }

  /**
   * Load the default query.
   */
  public loadDefaultQuery(projectIdentifier ?:string):ng.IPromise<QueryResource> {
    return this.fromQueryParams({}, projectIdentifier);
  }

  /**
   * Reloads the current query and set the pagination to the first page.
   */
  public reloadQuery(query:QueryResource):ng.IPromise<QueryResource> {
    let pagination = this.getPaginationInfo();
    pagination.offset = 1;

    this.clearDependentStates();

    let wpListPromise = this.QueryDm.reload(query, pagination);

    let promise = this.updateStatesFromQueryOnPromise(wpListPromise);

    promise
      .catch(error => {
        let projectIdentifier = query.project && query.project.id

        return this.handleQueryLoadingError(error, {}, query.id, projectIdentifier);
      });

    return this.conditionallyLoadForm(promise);
  }

  /**
   * Update the list from an existing query object.
   */
  public loadResultsList(query:QueryResource, additionalParams:PaginationObject):ng.IPromise<WorkPackageCollectionResource> {
    let wpListPromise = this.QueryDm.loadResults(query, additionalParams);

    return this.updateStatesFromWPListOnPromise(wpListPromise);
  }

  /**
   * Reload the list of work packages for the current query keeping the
   * pagination options.
   */
  public reloadCurrentResultsList():ng.IPromise<WorkPackageCollectionResource> {
    let pagination = this.getPaginationInfo();
    let query = this.currentQuery;

    return this.loadResultsList(query, pagination)
  }

  /**
   * Reload the first page of work packages for the current query
   */
  public loadCurrentResultsListFirstPage():ng.IPromise<WorkPackageCollectionResource> {
    let pagination = this.getPaginationInfo();
    pagination.offset = 1;
    let query = this.currentQuery;

    return this.loadResultsList(query, pagination)
  }

  public loadForm(query:QueryResource):ng.IPromise<QueryFormResource>{
    return this.QueryFormDm.load(query).then((form:QueryFormResource) => {
      this.updateStatesFromForm(query, form);

      return form;
    });
  }

  /**
   * Persist the current query in the backend.
   * After the update, the new query is reloaded (e.g. for the work packages)
   */
  public create(name:string) {
    let query = this.currentQuery;
    let form = this.states.table.form.getCurrentValue()!;

    query.name = name;

    let promise = this.QueryDm.create(query, form)

    promise
      .then(query => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_create'));
        this.reloadQuery(query);
      });

    return promise;
  }

  /**
   * Destroy the current query.
   */
  public delete() {
    let query = this.currentQuery;

    let promise = this.QueryDm.delete(query);

    promise
      .then(() => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_delete'));

        let id;
        if (query.project) {
          id = query.project.$href!.split('/').pop();
        }

        this.loadDefaultQuery(id);
      });

    return promise;
  }

  public save(query?:QueryResource) {
    query = query || this.currentQuery;

    let form = this.states.table.form.getCurrentValue()!;

    let promise = this.QueryDm.save(query, form);

    promise
      .then(() => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_update'));

        this
          .queryMenuItemFactory
          .renameMenuItem(query!.id, query!.name);

        // We should actually put the query newly received
        // from the backend in here.
        // But the backend does currently not return work packages (results).
        this.states.table.query.put(query!);
      })
      .catch((error:ErrorResource) => {
        this.NotificationsService.addError(error.message);
      });


    return promise;
  }

  public toggleStarred() {
    let query = this.currentQuery;

    let promise = this.QueryDm.toggleStarred(query);

    let starred = !query.starred;

    promise.then((query) => {
      this.states.table.query.put(query);

      this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_update'));

      this.updateQueryMenu()
    });

    return promise;
  }

  private getPaginationInfo() {
    let pagination = this.wpTablePagination.current;

    return {
      pageSize: pagination.perPage,
      offset: pagination.page
    };
  }

  private conditionallyLoadForm(promise:ng.IPromise<QueryResource>):ng.IPromise<QueryResource> {
    promise.then(query => {

      let currentForm = this.states.table.form.getCurrentValue();

      if (!currentForm || query.$links.update.$href !== currentForm.$href) {
        this.loadForm(query);
      }

      return query;
    })

    return promise;
  }

  private updateStatesFromQueryOnPromise(promise:ng.IPromise<QueryResource>):ng.IPromise<QueryResource> {
    promise
      .then(query => {
        this.updateStatesFromQuery(query);

        return query;
      });

    return promise;
  }

  private updateStatesFromWPListOnPromise(promise:ng.IPromise<WorkPackageCollectionResource>):ng.IPromise<WorkPackageCollectionResource> {
    return promise.then(this.updateStatesFromWPCollection.bind(this))
  }

  private updateStatesFromQuery(query:QueryResource) {
    this.updateStatesFromWPCollection(query.results);

    this.states.table.query.put(query);

    this.wpTableSum.initialize(query);
    this.wpTableColumns.initialize(query);
    this.wpTableGroupBy.initialize(query);

    this.AuthorisationService.initModelAuth('query', query.$links);
  }

  private updateStatesFromWPCollection(results:WorkPackageCollectionResource) {
    if (results.schemas) {
      _.each(results.schemas.elements, (schema:SchemaResource) => {
        this.states.schemas.get(schema.href as string).put(schema);
      });
    };

    this.$q.all(results.elements.map(wp => wp.schema.$load())).then(() => {
      this.states.table.rows.put(results.elements);
    });

    this.wpCacheService.updateWorkPackageList(results.elements);

    this.states.table.results.put(results);

    this.states.table.groups.put(angular.copy(results.groups));

    this.wpTablePagination.initialize(results);

    this.AuthorisationService.initModelAuth('work_package', results.$links);
  }

  private updateStatesFromForm(query:QueryResource, form:QueryFormResource) {
    let schema = form.schema as QuerySchemaResourceInterface;

    _.each(schema.filtersSchemas.elements, (schema:QueryFilterInstanceSchemaResource) => {
      this.states.schemas.get(schema.href as string).put(schema);
    });

    this.states.table.form.put(form);
    this.wpTableSortBy.initialize(query, schema);
    this.wpTableFilters.initialize(query, schema);
    this.wpTableGroupBy.update(query, schema);
    this.wpTableColumns.update(query, schema);
  }

  private clearDependentStates() {
    this.states.table.pagination.clear();
    this.states.table.filters.clear();
    this.states.table.columns.clear();
    this.states.table.sortBy.clear();
    this.states.table.groupBy.clear();
    this.states.table.sum.clear();
  }

  private get currentQuery() {
    return this.states.table.query.getCurrentValue()!;
  }

  private updateQueryMenu() {
    let query = this.currentQuery;

    if(query.starred) {
      this
        .queryMenuItemFactory
        .generateMenuItem(query.name,
                          this.$state.href('work-packages.list', { query_id: query.id }),
                          query.id);
    } else {
      this
        .queryMenuItemFactory
        .removeMenuItem(query.id);
    }

    this
      .queryMenuItemFactory
      .activateMenuItem();
  }

  private handleQueryLoadingError(error:ErrorResource, queryProps:any, queryId:number, projectIdentifier?:string) {
    let deferred = this.$q.defer();

    this.NotificationsService.addError(this.I18n.t('js.work_packages.faulty_query.description'), error.message);

    this.QueryFormDm.loadWithParams(queryProps, queryId, projectIdentifier)
      .then(form => {
        this.QueryDm.findDefault({ pageSize: 0 }, projectIdentifier)
          .then((query:QueryResource) => {
            this.wpListInvalidQueryService.restoreQuery(query, form);

            query.results.pageSize = queryProps.pageSize;
            query.results.total = 0;

            if (queryId) {
              query.id = queryId;
            }

            this.updateStatesFromQuery(query);
            this.updateStatesFromForm(query, form);

            deferred.resolve(query);
          });
    });

    return deferred.promise;
  }
}

angular
  .module('openproject.workPackages.services')
  .service('wpListService', WorkPackagesListService);
