timelinesApp.factory('ProjectType', ['$http', 'APIUrlHelper', function($http, APIUrlHelper) {

  // ProjectType = $resource(
  //   APIUrlHelper.apiPrefix + '/project_types/:id.json',
  //   {}, {
  //     get: {
  //       // Explicit specification needed because of API reponse format
  //       method: 'GET',
  //       transformResponse: function(data) {
  //         return new ProjectType(angular.fromJson(data).project_type);
  //       }
  //     },
  //     query: {
  //       // Explicit specification needed because of API reponse format
  //       method: 'GET',
  //       isArray: true,
  //       transformResponse: function(data) {
  //         wrapped = angular.fromJson(data);
  //         return wrapped.project_types;
  //       }
  //     }
  //   });


  ProjectType = function (data) {
     angular.extend(this, data);
  };

  ProjectType.collectionFromResponse = function(response) {
    return response.data.project_types.map(function(projectType){
      return new ProjectType(projectType);
    });
  };

  ProjectType.getCollection = function(params) {
    return $http({method: 'GET', url: APIUrlHelper.projectTypesPath(), params: params})
      .then(ProjectType.collectionFromResponse);
  };

  ProjectType.buildFromResponse = function(response) {
    return new ProjectType(response.data.project_type);
  };

  ProjectType.getById = function(id) {
    return $http.get(APIUrlHelper.projectTypePath(id))
      .then(ProjectType.buildFromResponse);
  };

  return ProjectType;
}]);
