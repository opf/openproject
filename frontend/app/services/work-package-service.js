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

module.exports = function($http,
    PathHelper,
    WorkPackagesHelper,
    HALAPIResource,
    DEFAULT_FILTER_PARAMS,
    DEFAULT_PAGINATION_OPTIONS,
    $rootScope,
    $window,
    $q,
    AuthorisationService,
    EditableFieldsState,
    WorkPackageFieldService
  ) {
  var workPackage;

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
            data._links[field] = value ? value.links.self.props : { href: null };
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
    getWorkPackage: function(id) {
      var resource = HALAPIResource.setup('work_packages/' + id);
      return resource.fetch().then(function (wp) {
        return $q.all([
          WorkPackageService.loadWorkPackageForm(wp),
          wp.links.schema.fetch()
        ]).then(function(result) {
            wp.form = result[0];
            wp.schema = result[1];
            workPackage = wp;
            EditableFieldsState.workPackage = wp;
            EditableFieldsState.errors = null;
            return wp;
          });
      });
    },

    getWorkPackagesByQueryId: function(projectIdentifier, queryId) {
      var url = projectIdentifier ? PathHelper.apiProjectWorkPackagesPath(projectIdentifier) : PathHelper.apiWorkPackagesPath();

      var params = queryId ? { query_id: queryId } : DEFAULT_FILTER_PARAMS;

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

    loadWorkPackageColumnsData: function(workPackages, columnNames, group_by) {
      var url = PathHelper.apiWorkPackagesColumnDataPath();

      var params = {
        'ids[]': workPackages.map(function(workPackage){
          return workPackage.id;
        }),
        'column_names[]': columnNames,
        'group_by': group_by
      };

      return WorkPackageService.doQuery(url, params);
    },

    // Note: Should this be on a project-service?
    getWorkPackagesSums: function(projectIdentifier, query, columns){
      var columnNames = columns.map(function(column){
        return column.name;
      });

      if (projectIdentifier){
        var url = PathHelper.apiProjectWorkPackagesSumsPath(projectIdentifier);
      } else {
        var url = PathHelper.apiWorkPackagesSumsPath();
      }

      var params = angular.extend(query.toParams(), {
        'column_names[]': columnNames
      });

      return WorkPackageService.doQuery(url, params);
    },

    augmentWorkPackagesWithColumnsData: function(workPackages, columns, group_by) {
      var columnNames = columns.map(function(column) {
        return column.name;
      });

      return WorkPackageService.loadWorkPackageColumnsData(workPackages, columnNames, group_by)
        .then(function(data){
          var columnsData = data.columns_data;
          var columnsMeta = data.columns_meta;

          angular.forEach(columns, function(column, i){
            column.total_sum = columnsMeta.total_sums[i];
            if (columnsMeta.group_sums) column.group_sums = columnsMeta.group_sums[i];

            angular.forEach(workPackages, function(workPackage, j) {
              WorkPackagesHelper.augmentWorkPackageWithData(workPackage, column.name, !!column.custom_field, columnsData[i][j]);
            });
          });

          return workPackages;
        });
    },

    loadWorkPackageForm: function(workPackage) {
      if (this.authorizedFor(workPackage, 'update')) {
        var options = { ajax: {
          method: 'POST',
          headers: {
            Accept: 'application/hal+json'
          },
          data:getPendingChanges(workPackage),
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

    updateWorkPackage: function(workPackage, notify) {
      var options = { ajax: {
        method: 'PATCH',
        url: URI(workPackage.links.updateImmediately.href).addSearch('notify', notify).toString(),
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
      return workPackage.links.addRelation.fetch(options).then(function(relation){
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
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      }).then(function(response){
                return response.data;
              },
              function(failedResponse) {
                $rootScope.$emit('flashMessage', {
                  isError: true,
                  isPermanent: true,
                  text: I18n.t('js.work_packages.query.errors.unretrievable_query')
                });
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
                $rootScope.$emit('flashMessage', {
                  isError: false,
                  text: I18n.t('js.work_packages.message_successful_bulk_delete')
                });
                $rootScope.$emit('workPackagesRefreshRequired');
              })
              .error(function(data, status) {
                // TODO wire up to API and processs API response
                $rootScope.$emit('flashMessage', {
                  isError: true,
                  text: I18n.t('js.work_packages.message_error_during_bulk_delete')
                });
              });
      }

      return promise;
    }
  };

  return WorkPackageService;
};
