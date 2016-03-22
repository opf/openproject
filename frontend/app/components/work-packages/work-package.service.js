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
/* globals URI */

angular
  .module('openproject.services')
  .factory('WorkPackageService', WorkPackageService);

function WorkPackageService($http, PathHelper, UrlParamsHelper, WorkPackagesHelper, HALAPIResource,
    DEFAULT_FILTER_PARAMS, DEFAULT_PAGINATION_OPTIONS, $rootScope, $window, $q, $cacheFactory,
    AuthorisationService, EditableFieldsState, WorkPackageFieldService, NotificationsService,
    inplaceEditErrors) {

  var workPackage,
      workPackageCache = $cacheFactory('workPackageCache');

  function getPendingChanges(workPackage) {
    var data = {
      // _links: {}
    };
    if (workPackage.form) {
      _.forEach(workPackage.form.pendingChanges, function(value, field) {
        if (WorkPackageFieldService.isSpecified(workPackage, field)) {
          if(field === 'date') {
            if(WorkPackageFieldService.isMilestone(workPackage)) {
              data['startDate'] = data['dueDate'] = value ? value : null;
              return;
            }
            data['startDate'] = value['startDate'];
            data['dueDate'] = value['dueDate'];
            return;
          }
          if (WorkPackageFieldService.isSavedAsLink(workPackage, field)) {
            data._links = data._links || {};
            data._links[field] = value ? value.props : { href: null };
          } else {
            data[field] = value;
          }
        }
      });
    }

    if (_.isEmpty(data)) {
      return null;
    } else {
      return JSON.stringify(data);
    }
  }

  var WorkPackageService = {
    initializeWorkPackage: function(projectIdentifier, initialData) {
      var changes = _.clone(initialData);
      var wp = {
        isNew: true,
        embedded: {},
        props: {},
        links: {
          update: HALAPIResource
            .setup(PathHelper
              .apiV3WorkPackageFormPath(projectIdentifier)),
          updateImmediately: HALAPIResource.setup(
            PathHelper.apiv3ProjectWorkPackagesPath(projectIdentifier),
            { method: 'post' }
          )
        }
      };
      var options = { ajax: {
          method: 'POST',
          headers: {
            Accept: 'application/hal+json'
          },
          data: JSON.stringify(changes),
          contentType: 'application/json; charset=utf-8'
        }};

      return wp.links.update.fetch(options)
        .then(function(form) {
          wp.form = form;
          EditableFieldsState.workPackage = wp;
          inplaceEditErrors.errors = null;

          wp.props = _.clone(form.embedded.payload.props);
          wp.links = _.extend(wp.links, _.clone(form.embedded.payload.links));

          return wp;
        });
    },

    initializeWorkPackageFromCopy: function(workPackage) {
      var projectIdentifier = workPackage.embedded.project.props.identifier;
      var initialData = _.clone(workPackage.form.embedded.payload.props);

      initialData._links = _.clone(workPackage.form.embedded.payload.links);
      delete initialData.lockVersion;

      return WorkPackageService.initializeWorkPackage(projectIdentifier, initialData);
    },

    initializeWorkPackageWithParent: function(parentWorkPackage) {
      var projectIdentifier = parentWorkPackage.embedded.project.props.identifier;

      var initialData = {
        _links: {
          parent: {
            href: PathHelper.apiV3WorkPackagePath(parentWorkPackage.props.id)
          }
        }
      };

      return WorkPackageService.initializeWorkPackage(projectIdentifier, initialData);
    },


    getWorkPackage: function(id) {
      var path = PathHelper.apiV3WorkPackagePath(id),
          resource = HALAPIResource.setup(path);

      return resource.fetch().then(function (wp) {
        return $q.all([
          WorkPackageService.loadWorkPackageForm(wp),
          wp.links.schema.fetch()
        ]).then(function(result) {
            wp.form = result[0];
            wp.schema = result[1];
            workPackage = wp;
            EditableFieldsState.workPackage = wp;
            inplaceEditErrors.errors = null;
            return wp;
          });
      });
    },

    getWorkPackagesByQueryId: function(projectIdentifier, queryId) {
      var url = projectIdentifier ? PathHelper.apiProjectWorkPackagesPath(projectIdentifier) : PathHelper.apiWorkPackagesPath();
      var params = queryId ? { queryId: queryId } : DEFAULT_FILTER_PARAMS;
      return WorkPackageService.doQuery(url, params);
    },

    getWorkPackages: function(projectIdentifier, query, paginationOptions) {
      var url = projectIdentifier ? PathHelper.apiProjectWorkPackagesPath(projectIdentifier) : PathHelper.apiWorkPackagesPath();
      var params = {};

      if(query) {
        angular.extend(params, query.toUpdateParams());
      }

      if(paginationOptions) {
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

    loadWorkPackageForm: function(workPackage) {
      if (this.authorizedFor(workPackage, 'update')) {
        var options = { ajax: {
          method: 'POST',
          headers: {
            Accept: 'application/hal+json'
          },
          data: getPendingChanges(workPackage),
          contentType: 'application/json; charset=utf-8'
        }, force: true};

        return workPackage.links.update.fetch(options).then(function(form) {
          workPackage.form = form;
          return form;
        });
      }

      return $q.when();
    },

    authorizedFor: function(workPackage, action) {
      var modelName = 'work_package' + workPackage.id;

      AuthorisationService.initModelAuth(modelName, workPackage.links);

      return AuthorisationService.can(modelName, action);
    },

    updateWithPayload: function(workPackage, payload) {
      var options = { ajax: {
        method: 'PATCH',
        url: workPackage.links.updateImmediately.href,
        headers: {
          Accept: 'application/hal+json'
        },
        data: JSON.stringify(payload),
        contentType: 'application/json; charset=utf-8'
      }, force: true};
      return workPackage.links.updateImmediately.fetch(options);
    },

    updateWorkPackage: function(workPackage) {
      var options = { ajax: {
        method: workPackage.links.updateImmediately.props.method,
        url: workPackage.links.updateImmediately.props.href,
        headers: {
          Accept: 'application/hal+json'
        },
        data: getPendingChanges(workPackage),
        contentType: 'application/json; charset=utf-8'
      }, force: true};
      return workPackage.links.updateImmediately.fetch(options);
    },

    addWorkPackageRelation: function(workPackage, toId, relationType) {
      var options = { ajax: {
        method: 'POST',
        data: JSON.stringify({
          to_id: toId,
          relation_type: relationType
        }),
        contentType: 'application/json; charset=utf-8'
      } };
      return workPackage.links.addRelation.fetch(options).then(function(relation) {
        return relation;
      });
    },

    removeWorkPackageRelation: function(relation) {
      var options = { ajax: { method: 'DELETE' } };
      return relation.links.remove.fetch(options).then(function(response){
        return response;
      });
    },

    doQuery: function(url, params) {
      return $http({
        method: 'GET',
        url: url,
        params: params,
        headers: {
          'caching': { enabled: false },
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }).then(function(response){
                return response.data;
              },
              function(failedResponse) {
                NotificationsService.addError(
                  I18n.t('js.work_packages.query.errors.unretrievable_query')
                );
              }
      );
    },

    performBulkDelete: function(ids, defaultHandling) {
      if (defaultHandling && !$window.confirm(I18n.t('js.text_work_packages_destroy_confirmation'))) {
        return;
      }

      var params = {
        'ids[]': ids
      };
      var promise = $http['delete'](PathHelper.workPackagesBulkDeletePath(), { params: params });

      if (defaultHandling) {
        promise.success(function(data, status) {
                // TODO wire up to API and process API response
                NotificationsService.addSuccess(
                  I18n.t('js.work_packages.message_successful_bulk_delete')
                );
                $rootScope.$emit('workPackagesRefreshRequired');
              })
              .error(function(data, status) {
                // FIXME catch this kind of failover in angular instead of redirecting
                // to a rails-based legacy view
                params = UrlParamsHelper.buildQueryString(params);
                window.location = PathHelper.workPackagesBulkDeletePath() + '?' + params;

                // TODO wire up to API and processs API response
                // NotificationsService.addError(
                //   I18n.t('js.work_packages.message_error_during_bulk_delete')
                // );
              });
      }

      return promise;
    },

    toggleWatch: function(workPackage) {
      var toggleWatchLink = (workPackage.links.watch === undefined) ?
                             workPackage.links.unwatch : workPackage.links.watch;
      var fetchOptions = { method: toggleWatchLink.props.method };

      if(toggleWatchLink.props.payload !== undefined) {
        fetchOptions.contentType = 'application/json; charset=utf-8';
        fetchOptions.data = JSON.stringify(toggleWatchLink.props.payload);
      }

      return toggleWatchLink.fetch({ajax: fetchOptions});
    },

    cache: function() {
      return workPackageCache;
    }
  };

  return WorkPackageService;
}
