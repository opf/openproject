//-- copyright
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
//++

angular
    .module('openproject.services')
    .factory('WorkPackageService', WorkPackageService);

function WorkPackageService($http,
                            $rootScope,
                            $window,
                            $q,
                            $cacheFactory,
                            $state,
                            PathHelper,
                            UrlParamsHelper,
                            DEFAULT_FILTER_PARAMS,
                            DEFAULT_PAGINATION_OPTIONS,
                            NotificationsService) {

  var workPackageCache = $cacheFactory('workPackageCache');

  var WorkPackageService = {

    getWorkPackagesByQueryId: function (projectIdentifier, queryId) {
      var url = projectIdentifier ? PathHelper.apiProjectWorkPackagesPath(projectIdentifier) : PathHelper.apiWorkPackagesPath();
      var params = queryId ? {queryId: queryId} : DEFAULT_FILTER_PARAMS;
      return WorkPackageService.doQuery(url, params);
    },

    getWorkPackages: function (projectIdentifier, query, paginationOptions) {
      var url = projectIdentifier ? PathHelper.apiProjectWorkPackagesPath(projectIdentifier) : PathHelper.apiWorkPackagesPath();
      var params = {};

      if (query) {
        angular.extend(params, query.toUpdateParams());
      }

      if (paginationOptions) {
        angular.extend(params, {
          page: paginationOptions.page,
          per_page: paginationOptions.perPage
        });
      } else {
        angular.extend(params, {
          page: DEFAULT_PAGINATION_OPTIONS.page,
          per_page: DEFAULT_PAGINATION_OPTIONS.perPage,
        });
      }

      return WorkPackageService.doQuery(url, params);
    },

    doQuery: function (url, params) {
      return $http({
        method: 'GET',
        url: url,
        params: params,
        headers: {
          'caching': {enabled: false},
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }).then(function (response) {
            return response.data;
          },
          function (failedResponse) {
            NotificationsService.addError(
                I18n.t('js.work_packages.query.errors.unretrievable_query')
            );
          }
      );
    },

    performBulkDelete: function (ids, defaultHandling) {
      if (defaultHandling && !$window.confirm(I18n.t('js.text_work_packages_destroy_confirmation'))) {
        return;
      }

      var params = {
        'ids[]': ids
      };
      var promise = $http['delete'](PathHelper.workPackagesBulkDeletePath(), {params: params});

      if (defaultHandling) {
        promise
            .then(function () {
              // TODO wire up to API and process API response
              NotificationsService.addSuccess(
                  I18n.t('js.work_packages.message_successful_bulk_delete')
              );
              $rootScope.$emit('workPackagesRefreshRequired');

              if ($state.includes('**.list.details.**')
                  && ids.indexOf(+$state.params.workPackageId) > -1) {
                $state.go('work-packages.list', $state.params);
              }
            })
            .catch(function () {
              // FIXME catch this kind of failover in angular instead of redirecting
              // to a rails-based legacy view
              params = UrlParamsHelper.buildQueryString(params);
              window.location = PathHelper.workPackagesBulkDeletePath() + '?' + params;
            });
      }

      return promise;
    },

    cache: function () {
      return workPackageCache;
    }

  };

  return WorkPackageService;
}
