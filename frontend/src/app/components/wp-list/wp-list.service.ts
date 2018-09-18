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

import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';
import {States} from '../states.service';
import {ErrorResource} from 'core-app/modules/hal/resources/error-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {WorkPackageTablePaginationService} from '../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackagesListInvalidQueryService} from './wp-list-invalid-query.service';
import {WorkPackageStatesInitializationService} from './wp-states-initialization.service';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {StateService} from '@uirouter/core';
import {WorkPackagesListChecksumService} from 'core-components/wp-list/wp-list-checksum.service';
import {LoadingIndicatorService} from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {Injectable} from '@angular/core';
import {QueryFormDmService} from 'core-app/modules/hal/dm-services/query-form-dm.service';
import {PaginationObject, QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BehaviorSubject} from 'rxjs/BehaviorSubject';

@Injectable()
export class WorkPackagesListService {
  private queryChanges = new BehaviorSubject<string>('');
  public queryChanges$ = this.queryChanges.asObservable();

  constructor(protected NotificationsService:NotificationsService,
              readonly I18n:I18nService,
              protected UrlParamsHelper:UrlParamsHelperService,
              protected authorisationService:AuthorisationService,
              protected $state:StateService,
              protected QueryDm:QueryDmService,
              protected QueryFormDm:QueryFormDmService,
              protected states:States,
              protected tableState:TableState,
              protected wpTablePagination:WorkPackageTablePaginationService,
              protected wpListChecksumService:WorkPackagesListChecksumService,
              protected wpStatesInitialization:WorkPackageStatesInitializationService,
              protected loadingIndicator:LoadingIndicatorService,
              protected wpListInvalidQueryService:WorkPackagesListInvalidQueryService) {
  }

  /**
   * Load a query.
   * The query is either a persisted query, identified by the query_id parameter, or the default query. Both will be modified by the parameters in the query_props parameter.
   */
  public fromQueryParams(queryParams:{ query_id?:number, query_props?:string }, projectIdentifier ?:string):Promise<QueryResource> {
    const decodedProps = this.getCurrentQueryProps(queryParams);
    const queryData = this.UrlParamsHelper.buildV3GetQueryFromJsonParams(decodedProps);
    const wpListPromise = this.QueryDm.find(queryData, queryParams.query_id, projectIdentifier);
    const promise = this.updateStatesFromQueryOnPromise(wpListPromise);

    promise
      .catch((error) => {
        const queryProps = this.UrlParamsHelper.buildV3GetQueryFromJsonParams(decodedProps);

        return this.handleQueryLoadingError(error, queryProps, queryParams.query_id, projectIdentifier);
      });

    return this.conditionallyLoadForm(promise);
  }

  /**
   * Get the current decoded query props, if any
   */
  public getCurrentQueryProps(params:{ query_props?:string }):string|null {
    if (!!params.query_props) {
      return decodeURIComponent(params.query_props);
    }

    return null;
  }

  /**
   * Load the default query.
   */
  public loadDefaultQuery(projectIdentifier ?:string):Promise<QueryResource> {
    return this.fromQueryParams({}, projectIdentifier);
  }

  /**
   * Reloads the current query and set the pagination to the first page.
   */
  public reloadQuery(query:QueryResource):Promise<QueryResource> {
    let pagination = this.getPaginationInfo();
    pagination.offset = 1;

    let wpListPromise = this.QueryDm.reload(query, pagination);

    let promise = this.updateStatesFromQueryOnPromise(wpListPromise);

    promise
      .catch((error) => {
        let projectIdentifier = query.project && query.project.id;

        return this.handleQueryLoadingError(error, {}, query.id, projectIdentifier);
      });

    return this.conditionallyLoadForm(promise);
  }

  /**
   * Update the list from an existing query object.
   */
  public loadResultsList(query:QueryResource, additionalParams:PaginationObject):Promise<WorkPackageCollectionResource> {
    let wpListPromise = this.QueryDm.loadResults(query, additionalParams);

    return this.updateStatesFromWPListOnPromise(query, wpListPromise);
  }

  /**
   * Reload the list of work packages for the current query keeping the
   * pagination options.
   */
  public reloadCurrentResultsList():Promise<WorkPackageCollectionResource> {
    let pagination = this.getPaginationInfo();
    let query = this.currentQuery;

    return this.loadResultsList(query, pagination);
  }

  /**
   * Reload the first page of work packages for the current query
   */
  public loadCurrentResultsListFirstPage():Promise<WorkPackageCollectionResource> {
    let pagination = this.getPaginationInfo();
    pagination.offset = 1;
    let query = this.currentQuery;

    return this.loadResultsList(query, pagination);
  }

  /**
   * Load the query from the given state params
   */
  public loadCurrentQueryFromParams(projectIdentifier?:string) {
    this.wpListChecksumService.clear();
    this.loadingIndicator.table.promise =
      this.fromQueryParams(this.$state.params as any, projectIdentifier).then(() => {
        return this.tableState.rendered.valuesPromise();
      });
  }

  public loadForm(query:QueryResource):Promise<QueryFormResource> {
    return this.QueryFormDm.load(query).then((form:QueryFormResource) => {
      this.wpStatesInitialization.updateStatesFromForm(query, form);

      return form;
    });
  }

  /**
   * Persist the current query in the backend.
   * After the update, the new query is reloaded (e.g. for the work packages)
   */
  public create(query:QueryResource, name:string):Promise<QueryResource> {
    let form = this.states.query.form.value!;

    query.name = name;

    let promise = this.QueryDm.create(query, form);

    promise
      .then(query => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_create'));

        // Reload the query, and then reload the menu
        this.reloadQuery(query).then(() => {
          this.queryChanges.next(query.name);
        });

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

        let id;
        if (query.project) {
          id = query.project.$href!.split('/').pop();
        }

        this.loadDefaultQuery(id);


        this.queryChanges.next(query.name);
      });


    return promise;
  }

  public save(query?:QueryResource) {
    query = query || this.currentQuery;

    let form = this.states.query.form.value!;

    let promise = this.QueryDm.update(query, form);

    promise
      .then(() => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_update'));

        this.$state.go('.', { query_id: query!.id, query_props: null }, { reload: true });
        this.queryChanges.next(query!.name);
      })
      .catch((error:ErrorResource) => {
        this.NotificationsService.addError(error.message);
      });

    return promise;
  }

  public toggleStarred(query:QueryResource):Promise<any> {
    let promise = this.QueryDm.toggleStarred(query);

    promise.then((query:QueryResource) => {
      this.states.query.resource.putValue(query);

      this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_update'));

      this.queryChanges.next(query.name);
    });

    return promise;
  }

  private getPaginationInfo() {
    return this.wpTablePagination.paginationObject;
  }

  private conditionallyLoadForm(promise:Promise<QueryResource>):Promise<QueryResource> {
    promise.then(query => {

      let currentForm = this.states.query.form.value;

      if (!currentForm || query.$links.update.$href !== currentForm.$href) {
        setTimeout(() => this.loadForm(query), 0);
      }

      return query;
    });

    return promise;
  }

  private updateStatesFromQueryOnPromise(promise:Promise<QueryResource>):Promise<QueryResource> {
    promise
      .then(query => {
        this.tableState.ready.doAndTransition('Query loaded', () => {
          this.wpStatesInitialization.initialize(query, query.results);
          return this.tableState.tableRendering.onQueryUpdated.valuesPromise();
        });

        return query;
      });

    return promise;
  }

  private updateStatesFromWPListOnPromise(query:QueryResource, promise:Promise<WorkPackageCollectionResource>):Promise<WorkPackageCollectionResource> {
    return promise.then((results) => {
      this.tableState.ready.doAndTransition('Query loaded', () => {
        this.wpStatesInitialization.updateTableState(query, results);
        this.wpStatesInitialization.updateChecksum(query, results);
        return this.tableState.tableRendering.onQueryUpdated.valuesPromise();
      });

      return results;
    });
  }

  public get currentQuery() {
    return this.states.query.resource.value!;
  }

  private handleQueryLoadingError(error:ErrorResource, queryProps:any, queryId?:number, projectIdentifier?:string) {
    this.NotificationsService.addError(this.I18n.t('js.work_packages.faulty_query.description'), error.message);

    return new Promise((resolve, reject) => {
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

              this.tableState.ready.doAndTransition('Query loaded', () => {
                this.wpStatesInitialization.initialize(query, query.results);
                this.wpStatesInitialization.updateStatesFromForm(query, form);

                return this.tableState.tableRendering.onQueryUpdated.valuesPromise();
              });

              resolve(query);
            })
            .catch(reject);
        })
        .catch(reject);
    });
  }
}
