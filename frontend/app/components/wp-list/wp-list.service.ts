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
import {PaginationObject, QueryDmService} from '../api/api-v3/hal-resource-dms/query-dm.service';
import {QueryFormDmService} from '../api/api-v3/hal-resource-dms/query-form-dm.service';
import {States} from '../states.service';
import {ErrorResource} from '../api/api-v3/hal-resources/error-resource.service';
import {WorkPackageCollectionResource} from '../api/api-v3/hal-resources/wp-collection-resource.service';
import {WorkPackageTablePaginationService} from '../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackagesListInvalidQueryService} from './wp-list-invalid-query.service';
import {WorkPackageStatesInitializationService} from './wp-states-initialization.service';

export class WorkPackagesListService {
  constructor(protected NotificationsService:any,
              protected UrlParamsHelper:any,
              protected AuthorisationService:any,
              protected $q:ng.IQService,
              protected $state:any,
              protected QueryDm:QueryDmService,
              protected QueryFormDm:QueryFormDmService,
              protected states:States,
              protected wpTablePagination:WorkPackageTablePaginationService,
              protected wpStatesInitialization:WorkPackageStatesInitializationService,
              protected wpListInvalidQueryService:WorkPackagesListInvalidQueryService,
              protected I18n:op.I18n,
              protected queryMenuItemFactory:any) {
  }

  /**
   * Load a query.
   * The query is either a persisted query, identified by the query_id parameter, or the default query. Both will be modified by the parameters in the query_props parameter.
   */
  public fromQueryParams(queryParams:any, projectIdentifier ?:string):ng.IPromise<QueryResource> {
    const queryData = this.UrlParamsHelper.buildV3GetQueryFromJsonParams(queryParams.query_props);
    const wpListPromise = this.QueryDm.find(queryData, queryParams.query_id, projectIdentifier);
    const promise = this.updateStatesFromQueryOnPromise(wpListPromise);

    promise
      .catch(error => {
        const queryProps = this.UrlParamsHelper.buildV3GetQueryFromJsonParams(queryParams.query_props);

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

    let wpListPromise = this.QueryDm.reload(query, pagination);

    let promise = this.updateStatesFromQueryOnPromise(wpListPromise);

    promise
      .catch(error => {
        let projectIdentifier = query.project && query.project.id;

        return this.handleQueryLoadingError(error, {}, query.id, projectIdentifier);
      });

    return this.conditionallyLoadForm(promise);
  }

  /**
   * Update the list from an existing query object.
   */
  public loadResultsList(query:QueryResource, additionalParams:PaginationObject):ng.IPromise<WorkPackageCollectionResource> {
    let wpListPromise = this.QueryDm.loadResults(query, additionalParams);

    return this.updateStatesFromWPListOnPromise(query, wpListPromise);
  }

  /**
   * Reload the list of work packages for the current query keeping the
   * pagination options.
   */
  public reloadCurrentResultsList():ng.IPromise<WorkPackageCollectionResource> {
    let pagination = this.getPaginationInfo();
    let query = this.currentQuery;

    return this.loadResultsList(query, pagination);
  }

  /**
   * Reload the first page of work packages for the current query
   */
  public loadCurrentResultsListFirstPage():ng.IPromise<WorkPackageCollectionResource> {
    let pagination = this.getPaginationInfo();
    pagination.offset = 1;
    let query = this.currentQuery;

    return this.loadResultsList(query, pagination);
  }

  public loadForm(query:QueryResource):ng.IPromise<QueryFormResource> {
    return this.QueryFormDm.load(query).then((form:QueryFormResource) => {
      this.wpStatesInitialization.updateStatesFromForm(query, form);

      return form;
    });
  }

  /**
   * Persist the current query in the backend.
   * After the update, the new query is reloaded (e.g. for the work packages)
   */
  public create(query:QueryResource, name:string):ng.IPromise<QueryResource> {
    let form = this.states.query.form.value!;

    query.name = name;

    let promise = this.QueryDm.create(query, form);

    promise
      .then(query => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_create'));
        this.reloadQuery(query);
        return query;
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

        this.removeMenuItem(query);

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

    let form = this.states.query.form.value!;

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
        this.states.query.resource.putValue(query!);
      })
      .catch((error:ErrorResource) => {
        this.NotificationsService.addError(error.message);
      });

    return promise;
  }

  public toggleStarred(query:QueryResource):ng.IPromise<any> {
    let promise = this.QueryDm.toggleStarred(query);

    promise.then((query) => {
      this.states.query.resource.putValue(query);

      this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_update'));

      this.updateQueryMenu();
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

      let currentForm = this.states.query.form.value;

      if (!currentForm || query.$links.update.$href !== currentForm.$href) {
        setTimeout(() => this.loadForm(query), 0);
      }

      return query;
    });

    return promise;
  }

  private updateStatesFromQueryOnPromise(promise:ng.IPromise<QueryResource>):ng.IPromise<QueryResource> {
    promise
      .then(query => {
        this.states.query.context.doAndTransition('Query loaded', () => {
          this.wpStatesInitialization.initialize(query, query.results);
          return this.states.tableRendering.onQueryUpdated.valuesPromise();
        });

        return query;
      });

    return promise;
  }

  private updateStatesFromWPListOnPromise(query:QueryResource, promise:ng.IPromise<WorkPackageCollectionResource>):ng.IPromise<WorkPackageCollectionResource> {
    return promise.then((results) => {
      this.states.query.context.doAndTransition('Query loaded', () => {
        this.wpStatesInitialization.updateFromResults(results);
        return this.states.tableRendering.onQueryUpdated.valuesPromise();
      });

      return results;
    });
  }

  private get currentQuery() {
    return this.states.query.resource.value!;
  }

  private updateQueryMenu() {
    let query = this.currentQuery;

    if (query.starred) {
      this.createMenuItem(query);
    } else {
      this.removeMenuItem(query);
    }

    this.activateMenuItem();
  }

  private handleQueryLoadingError(error:ErrorResource, queryProps:any, queryId:number, projectIdentifier?:string) {
    let deferred = this.$q.defer();

    this.NotificationsService.addError(this.I18n.t('js.work_packages.faulty_query.description'), error.message);

    this.QueryFormDm.loadWithParams(queryProps, queryId, projectIdentifier)
      .then(form => {
        this.QueryDm.findDefault({pageSize: 0}, projectIdentifier)
          .then((query:QueryResource) => {
            this.wpListInvalidQueryService.restoreQuery(query, form);

            query.results.pageSize = queryProps.pageSize;
            query.results.total = 0;

            if (queryId) {
              query.id = queryId;
            }

            this.states.query.context.doAndTransition('Query loaded', () => {
              this.wpStatesInitialization.initialize(query, query.results);
              this.wpStatesInitialization.updateStatesFromForm(query, form);

              return this.states.tableRendering.onQueryUpdated.valuesPromise();
            });

            deferred.resolve(query);
          });
      });

    return deferred.promise;
  }

  private createMenuItem(query:QueryResource) {
    this
      .queryMenuItemFactory
      .generateMenuItem(query.name,
        this.$state.href('work-packages.list', {query_id: query.id}),
        query.id);
  }

  private removeMenuItem(query:QueryResource) {
    this
      .queryMenuItemFactory
      .removeMenuItem(query.id);
  }

  private activateMenuItem() {
    this
      .queryMenuItemFactory
      .activateMenuItem();
  }
}

angular
  .module('openproject.workPackages.services')
  .service('wpListService', WorkPackagesListService);
