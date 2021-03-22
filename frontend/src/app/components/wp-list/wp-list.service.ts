//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { QueryFormResource } from 'core-app/modules/hal/resources/query-form-resource';
import { States } from '../states.service';
import { ErrorResource } from 'core-app/modules/hal/resources/error-resource';
import { WorkPackageCollectionResource } from 'core-app/modules/hal/resources/wp-collection-resource';
import { WorkPackagesListInvalidQueryService } from './wp-list-invalid-query.service';
import { WorkPackageStatesInitializationService } from './wp-states-initialization.service';
import { AuthorisationService } from 'core-app/modules/common/model-auth/model-auth.service';
import { StateService } from '@uirouter/core';
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { Injectable } from '@angular/core';
import { UrlParamsHelperService } from 'core-components/wp-query/url-params-helper';
import { NotificationsService } from 'core-app/modules/common/notifications/notifications.service';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { from, Observable, of } from 'rxjs';
import { input } from "reactivestates";
import { catchError, mergeMap, share, switchMap, take } from "rxjs/operators";
import {
  PaginationUpdateObject,
  WorkPackageViewPaginationService
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-pagination.service";
import { ConfigurationService } from "core-app/modules/common/config/configuration.service";
import { PaginationService } from "core-components/table-pagination/pagination-service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { APIv3QueriesPaths } from "core-app/modules/apiv3/endpoints/queries/apiv3-queries-paths";
import { APIv3QueryPaths } from "core-app/modules/apiv3/endpoints/queries/apiv3-query-paths";

export interface QueryDefinition {
  queryParams:{ query_id?:string, query_props?:string };
  projectIdentifier?:string;
}

@Injectable()
export class WorkPackagesListService {

  // We remember the query requests coming in so we can ensure only the latest request is being tended to
  private queryRequests = input<QueryDefinition>();

  // This mapped observable requests the latest query automatically.
  private queryLoading = this.queryRequests
    .values$()
    .pipe(
      switchMap((q:QueryDefinition) => {
        return from(this.ensurePerPageKnown().then(() => q));
      }),
      // Stream the query request, switchMap will call previous requests to be cancelled
      switchMap((q:QueryDefinition) =>
        this.streamQueryRequest(q.queryParams, q.projectIdentifier)
      ),
      // Map the observable from the stream to a new one that completes when states are loaded
      mergeMap((query:QueryResource) => {
        // load the form if needed
        this.conditionallyLoadForm(query);

        // Project the loaded query into the table states and confirm the query is fully loaded
        this.wpStatesInitialization.initialize(query, query.results);
        return of(query);
      }),
      // Share any consecutive requests to the same resource, this is due to switchMap
      // diverting observables to the LATEST emitted.
      share()
    );

  constructor(protected NotificationsService:NotificationsService,
              readonly I18n:I18nService,
              protected UrlParamsHelper:UrlParamsHelperService,
              protected authorisationService:AuthorisationService,
              protected $state:StateService,
              protected apiV3Service:APIV3Service,
              protected states:States,
              protected querySpace:IsolatedQuerySpace,
              protected pagination:PaginationService,
              protected configuration:ConfigurationService,
              protected wpTablePagination:WorkPackageViewPaginationService,
              protected wpStatesInitialization:WorkPackageStatesInitializationService,
              protected wpListInvalidQueryService:WorkPackagesListInvalidQueryService) {
  }

  /**
   * Stream a query request as a HTTP observable. Each request to this method will
   * result in a new HTTP request.
   *
   * @param queryParams
   * @param projectIdentifier
   */
  private streamQueryRequest(queryParams:{ query_id?:string, query_props?:string }, projectIdentifier?:string):Observable<QueryResource> {
    const decodedProps = this.getCurrentQueryProps(queryParams);
    const queryData = this.UrlParamsHelper.buildV3GetQueryFromJsonParams(decodedProps);
    const stream = this
      .apiV3Service
      .queries
      .find(queryData, queryParams.query_id, projectIdentifier);

    return stream.pipe(
      catchError((error) => {
        // Load a default query
        const queryProps = this.UrlParamsHelper.buildV3GetQueryFromJsonParams(decodedProps);
        return from(this.handleQueryLoadingError(error, queryProps, queryParams.query_id, projectIdentifier));
      })
    );
  }

  /**
   * Load a query.
   * The query is either a persisted query, identified by the query_id parameter, or the default query. Both will be modified by the parameters in the query_props parameter.
   */
  public fromQueryParams(queryParams:{ query_id?:string, query_props?:string }, projectIdentifier?:string):Observable<QueryResource> {
    this.queryRequests.clear();
    this.queryRequests.putValue({ queryParams: queryParams, projectIdentifier: projectIdentifier });

    return this
      .queryLoading
      .pipe(
        take(1)
      );
  }

  /**
   * Get the current decoded query props, if any
   */
  public getCurrentQueryProps(params:{ query_props?:string }):string|null {
    if (params.query_props) {
      return decodeURIComponent(params.query_props);
    }

    return null;
  }

  /**
   * Load the default query.
   */
  public loadDefaultQuery(projectIdentifier?:string):Promise<QueryResource> {
    return this.fromQueryParams({}, projectIdentifier).toPromise();
  }

  /**
   * Reloads the current query and set the pagination to the first page.
   */
  public reloadQuery(query:QueryResource, projectIdentifier?:string):Observable<QueryResource> {
    const pagination = { ...this.wpTablePagination.current, page: 1 };
    const queryParams = this.UrlParamsHelper.encodeQueryJsonParams(query, pagination);

    this.queryRequests.clear();
    this.queryRequests.putValue({
      queryParams: { query_id: query.id || undefined, query_props: queryParams },
      projectIdentifier: projectIdentifier
    });

    return this
      .queryLoading
      .pipe(
        take(1)
      );
  }

  /**
   * Update the query from an existing (probably unsaved) query.
   *
   * Will choose the correct path:
   * - If the query is unsaved, use `/api/v3(/projects/:identifier)/queries/default`
   * - If the query is saved, use `/api/v3/queries/:id`
   *
   */
  public loadQueryFromExisting(query:QueryResource, additionalParams:Object, projectIdentifier?:string):Observable<QueryResource> {
    const params = this.UrlParamsHelper.buildV3GetQueryFromQueryResource(query, additionalParams);

    let path:APIv3QueriesPaths|APIv3QueryPaths;

    if (query.id) {
      path = this.apiV3Service.queries.id(query.id);
    } else {
      path = this.apiV3Service.withOptionalProject(projectIdentifier).queries;
    }

    return path.parameterised(params);
  }

  /**
   * Load the query from the given state params
   */
  public loadCurrentQueryFromParams(projectIdentifier?:string) {
    return this
      .fromQueryParams(this.$state.params as any, projectIdentifier)
      .toPromise();
  }

  public loadForm(query:QueryResource):Promise<QueryFormResource> {
    return this
      .apiV3Service
      .queries
      .form
      .load(query)
      .toPromise()
      .then(([form, _]) => {
        this.wpStatesInitialization.updateStatesFromForm(query, form);

        return form;
      });
  }

  /**
   * Persist the current query in the backend.
   * After the update, the new query is reloaded (e.g. for the work packages)
   */
  public create(query:QueryResource, name:string):Promise<QueryResource> {
    const form = this.querySpace.queryForm.value!;

    query.name = name;

    const promise = this
      .apiV3Service
      .queries
      .post(query, form)
      .toPromise();

    promise
      .then(query => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_create'));

        // Reload the query, and then reload the menu
        this.reloadQuery(query).subscribe(() => {
          this.states.changes.queries.next(query.id!);
        });

        return query;
      });

    return promise;
  }

  /**
   * Destroy the current query.
   */
  public delete() {
    const query = this.currentQuery;

    const promise = this
      .apiV3Service
      .queries
      .id(query)
      .delete()
      .toPromise();

    promise
      .then(() => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_delete'));

        let id;
        if (query.project) {
          id = query.project.$href!.split('/').pop();
        }

        this.loadDefaultQuery(id);

        this.states.changes.queries.next(query.id!);
      });


    return promise;
  }

  public save(query?:QueryResource) {
    query = query || this.currentQuery;

    const form = this.querySpace.queryForm.value!;

    const promise = this
      .apiV3Service
      .queries
      .id(query)
      .patch(query, form)
      .toPromise();

    promise
      .then(() => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_update'));

        this.$state.go('.', { query_id: query!.id, query_props: null }, { reload: true });
        this.states.changes.queries.next(query!.id!);
      })
      .catch((error:ErrorResource) => {
        this.NotificationsService.addError(error.message);
      });

    return promise;
  }

  public toggleStarred(query:QueryResource):Promise<any> {
    const promise = this
      .apiV3Service
      .queries
      .toggleStarred(query);

    promise.then((query:QueryResource) => {
      this.querySpace.query.putValue(query);

      this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_update'));

      this.states.changes.queries.next(query!.id!);
    });

    return promise;
  }

  public getPaginationInfo() {
    return this.wpTablePagination.paginationObject;
  }

  private conditionallyLoadForm(query:QueryResource):void {
    const currentForm = this.querySpace.queryForm.value;

    if (!currentForm || query.$links.update.$href !== currentForm.$href) {
      setTimeout(() => this.loadForm(query), 0);
    }
  }

  private updateStatesFromQueryOnPromise(promise:Promise<QueryResource>):Promise<QueryResource> {
    promise
      .then(query => {
        this.wpStatesInitialization.initialize(query, query.results);
        return query;
      });

    return promise;
  }

  public get currentQuery() {
    return this.querySpace.query.value!;
  }

  private handleQueryLoadingError(error:ErrorResource, queryProps:any, queryId?:string, projectIdentifier?:string|null):Promise<QueryResource> {
    this.NotificationsService.addError(this.I18n.t('js.work_packages.faulty_query.description'), error.message);

    return new Promise((resolve, reject) => {
      this
        .apiV3Service
        .queries
        .form
        .loadWithParams(queryProps, queryId, projectIdentifier)
        .toPromise()
        .then(([form, _]) => {
          this
            .apiV3Service
            .queries
            .find({ pageSize: 0 }, undefined, projectIdentifier)
            .toPromise()
            .then((query:QueryResource) => {
              this.wpListInvalidQueryService.restoreQuery(query, form);

              query.results.pageSize = queryProps.pageSize;
              query.results.total = 0;

              if (queryId) {
                query.id = queryId;
              }

              this.wpStatesInitialization.initialize(query, query.results);
              this.wpStatesInitialization.updateStatesFromForm(query, form);

              resolve(query);
            })
            .catch(reject);
        })
        .catch(reject);
    });
  }

  private async ensurePerPageKnown() {
    if (this.pagination.isPerPageKnown) {
      return true;
    } else {
      return this.configuration.initialized;
    }
  }
}
