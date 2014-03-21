angular.module('openproject.services')

.service('QueryService', ['$http', 'PathHelper', '$q', 'AVAILABLE_WORK_PACKAGE_FILTERS', 'StatusService', 'TypeService', 'PriorityService', 'UserService', function($http, PathHelper, $q, AVAILABLE_WORK_PACKAGE_FILTERS, StatusService, TypeService, PriorityService, UserService) {

  var availableColumns = [], availableFilterValues = {};

  var QueryService = {
    getAvailableColumns: function(projectId) {
      var url = PathHelper.apiAvailableColumnsPath(projectId);

      return QueryService.doQuery(url);
    },

    getAvailableFilterValues: function(filterName) {
      var modelName = AVAILABLE_WORK_PACKAGE_FILTERS[filterName].modelName;

      if(availableFilterValues[modelName]) {
        return $q.when(availableFilterValues[modelName]);
      } else {
        var retrieveAvailableValues;

        switch(modelName) {
          case 'status':
            retrieveAvailableValues = StatusService.getStatuses();
            break;
          case 'type':
            retrieveAvailableValues = TypeService.getTypes();
            break;
          case 'priority':
            retrieveAvailableValues = TypeService.getPriorities();
            break;
          case 'user':
            retrieveAvailableValues = UserService.getUsers();
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
