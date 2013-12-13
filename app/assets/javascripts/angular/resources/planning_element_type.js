timelinesApp.factory('PlanningElementType', ['$resource', 'APIDefaults', function($resource, APIDefaults) {

  PlanningElementType = $resource(
    APIDefaults.apiPrefix + '/planning_element_types/:id.json',
    {}, {
      get: {
        // Explicit specification needed because of API reponse format
        method: 'GET',
        transformResponse: function(data) {
          return new PlanningElementType(angular.fromJson(data).project_type);
        }
      },
      query: {
        // Explicit specification needed because of API reponse format
        method: 'GET',
        isArray: true,
        transformResponse: function(data) {
          wrapped = angular.fromJson(data);
          return wrapped.planning_element_types;
        }
      }
    });

  return PlanningElementType;
}]);
