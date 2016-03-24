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

export class WorkPackagesListService {
  constructor(protected apiWorkPackages,
              protected WorkPackageService,
              protected QueryService,
              protected PaginationService,
              protected NotificationsService,
              protected UrlParamsHelper,
              protected $location,
              protected $q,
              protected Query,
              protected I18n) {}

  /**
   * Resolve API experimental and APIv3 requests using queryParams.
   */
  public fromQueryParams(queryParams:any, projectIdentifier ?:string):ng.IPromise<api.ex.WorkPackagesMeta> {
    var wpListPromise = this.listFromParams(queryParams, projectIdentifier);
    return this.resolveList(wpListPromise);
  }

  /**
   * Update the list from an existing query object.
   */
  public fromQueryInstance(query:op.Query, projectIdentifier:string) {
    var paginationOptions = this.PaginationService.getPaginationOptions();
    var wpListPromise = this.WorkPackageService.getWorkPackages(projectIdentifier, query, paginationOptions);
    return this.resolveList(wpListPromise);
  }

  /**
   * Figure out the correct list promise from query state parameters.
   */
  private listFromParams(queryParams:any, projectIdentifier ?:string):ng.IPromise<any> {
    var fetchWorkPackages;

    if (queryParams.query_props) {
      try {
        var queryData = this.UrlParamsHelper.decodeQueryFromJsonParams(queryParams.query_id, queryParams.query_props);
        var queryFromParams = new this.Query(queryData, {rawFilters: true});

        fetchWorkPackages = this.WorkPackageService.getWorkPackages(
          projectIdentifier, queryFromParams, this.PaginationService.getPaginationOptions());

      } catch (e) {
        this.NotificationsService.addError(
          this.I18n.t('js.work_packages.query.errors.unretrievable_query')
        );
        this.clearUrlQueryParams();

        fetchWorkPackages = this.WorkPackageService.getWorkPackages(projectIdentifier);
      }

    } else if (queryParams.query_id) {
      // Load the query by id if present
      fetchWorkPackages = this.WorkPackageService.getWorkPackagesByQueryId(projectIdentifier, queryParams.query_id);

    } else {
      // Clear the cached query and load the default
      this.QueryService.clearQuery();
      fetchWorkPackages = this.WorkPackageService.getWorkPackages(projectIdentifier);
    }

    return fetchWorkPackages;
  }

  public clearUrlQueryParams() {
    this.$location.search('query_props', null);
    this.$location.search('query_id', null);
  }

  /**
   * Resolve the query with experimental API and load work packages through APIv3.
   */
  private resolveList(wpListPromise):ng.IPromise<api.ex.WorkPackagesMeta> {
    var deferred = this.$q.defer();

    wpListPromise.then((json:api.ex.WorkPackagesMeta) => {
      this.apiWorkPackages
        .list(json.meta.page, json.meta.per_page, json.meta.query)
        .then((workPackageCollection) => {
          this.mergeApiResponses(json, workPackageCollection);

          deferred.resolve(json);
        });
    });

    return deferred.promise;
  }

  /**
   * Temporarily merge responses from experimental and v3 API.
   * This will have to be reworked when we retrieve data from APIv3 Query endpoint.
   * @param exJson
   * @param workPackages
   */
  private mergeApiResponses(exJson, workPackages) {
    exJson.work_packages = workPackages.elements;
    exJson.resource = workPackages;
  }
}

angular
  .module('openproject.workPackages.services')
  .service('wpListService', WorkPackagesListService);
