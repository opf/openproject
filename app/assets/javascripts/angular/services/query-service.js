angular.module('openproject.services')

.service('QueryService', ['$http', 'PathHelper', '$q', 'AVAILABLE_WORK_PACKAGE_FILTERS', 'StatusService', 'TypeService', 'PriorityService', 'UserService', 'VersionService', 'RoleService', 'GroupService', function($http, PathHelper, $q, AVAILABLE_WORK_PACKAGE_FILTERS, StatusService, TypeService, PriorityService, UserService, VersionService, RoleService, GroupService) {

  var availableColumns = [], availableFilterValues = {};

  var QueryService = {
    getAvailableColumns: function(projectIdentifier) {
      var url = projectIdentifier ? PathHelper.apiProjectAvailableColumnsPath(projectIdentifier) : PathHelper.apiAvailableColumnsPath();

      return QueryService.doQuery(url);
    },

    getAvailableFilterValues: function(filterName, projectIdentifier) {
      var modelName = AVAILABLE_WORK_PACKAGE_FILTERS[filterName].modelName;

      if(availableFilterValues[modelName]) {
        return $q.when(availableFilterValues[modelName]);
      } else {
        var retrieveAvailableValues;

        switch(modelName) {
          case 'status':
            retrieveAvailableValues = StatusService.getStatuses(projectIdentifier);
            break;
          case 'type':
            retrieveAvailableValues = TypeService.getTypes(projectIdentifier);
            break;
          case 'priority':
            retrieveAvailableValues = PriorityService.getPriorities(projectIdentifier);
            break;
          case 'user':
            retrieveAvailableValues = UserService.getUsers(projectIdentifier);
            break;
          case 'version':
            retrieveAvailableValues = VersionService.getProjectVersions(projectIdentifier);
            break;
          case 'role':
            retrieveAvailableValues = RoleService.getRoles();
            break;
          case 'group':
            retrieveAvailableValues = GroupService.getGroups();
            break;
        }

        return retrieveAvailableValues.then(function(values) {
          return QueryService.storeAvailableFilterValues(modelName, values);
        });
      }
    },

    storeAvailableFilterValues: function(modelName, values) {
      availableFilterValues[modelName] = values;
      return values;
    },

    doQuery: function(url, params) {
      return $http({
        method: 'GET',
        url: url,
        params: params,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      }).then(function(response){
        return response.data;
      });
    }
  };

  return QueryService;
}]);
