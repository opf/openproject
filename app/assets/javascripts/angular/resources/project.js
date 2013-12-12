timelinesApp.factory('Project', ['$resource', 'APIDefaults', function($resource, APIDefaults) {

  Project = $resource(
    APIDefaults.apiPrefix + '/projects/:id.json',
    {id: '@projectId'},
    {
      get: {
        // Explicit specification needed because of API reponse format
        method: 'GET',
        transformResponse: function(data) {
          return new Project(angular.fromJson(data).project);
        }
      },
      query: {
        method: 'GET',
        isArray: true,
        transformResponse: function(data) {
          // Angular resource expects a json array and would return json
          // Work around as the API does not return an array.
          wrapped = angular.fromJson(data);
          angular.forEach(wrapped.projects, function(item, idx) {
            // transform JSON into resource object
            wrapped.projects[idx] = new Project(item);
          });
          return wrapped.projects;
        }
      }
    });

  Project.prototype.getParent = function() {
    if(!this.parent) return null;

    if(!this.parentProject) {
      this.parentProject = Project.get({id: this.parent.id});
    }
    return this.parentProject;
  };

  Project.prototype.getChildren = function() {
    if(!this.children) {
      this.children = Project.query({parent_id: this.id});
    }
    return this.children;
  };

  return Project;
}]);
