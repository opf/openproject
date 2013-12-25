timelinesApp.factory('PlanningElementType', ['$http', 'APIUrlHelper', function($http, APIUrlHelper) {
  PlanningElementType = function (data) {
     angular.extend(this, data);
  };

  PlanningElementType.collectionFromResponse = function(response) {
    return response.data.planning_element_types.map(function(planningElementType){
      return new PlanningElementType(planningElementType);
    });
  };

  PlanningElementType.getCollection = function(params) {
    return $http({method: 'GET', url: APIUrlHelper.planningElementTypesPath(), params: params})
      .then(PlanningElementType.collectionFromResponse);
  };

  PlanningElementType.buildFromResponse = function(response) {
    return new PlanningElementType(response.data.planning_element_type);
  };

  PlanningElementType.getById = function(id) {
    return $http.get(APIUrlHelper.planningElementTypePath(id))
      .then(PlanningElementType.buildFromResponse);
  };

  return PlanningElementType;
}]);
