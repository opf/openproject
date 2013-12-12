timelinesApp.factory('ProjectType', ['$resource', 'APIDefaults', function($resource, APIDefaults) {

  ProjectType = $resource(
    APIDefaults.apiPrefix + '/project_types/:id.json',
    {}, {
      query: {
        method: 'GET',
        isArray: true,
        transformResponse: function(data) {
          wrapped = angular.fromJson(data);
          return wrapped.project_types;
        }
      }
    });

  ProjectType.identifier = 'project_types';

  return ProjectType;
}]);
