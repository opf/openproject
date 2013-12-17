timelinesApp.service('Reporting', ['$resource', '$q', 'Project', 'Status', function($resource, $q, Project, Status) {

  apiPrefix = '/api/v2';
  projectPath = '/projects/:projectId';

  Reporting = $resource(
    apiPrefix + projectPath + '/reportings/:id.json',
    {projectId: '@projectId', id: '@reportingId'},
    {
      get: {
        // Explicit specification needed because of API reponse format
        method: 'GET',
        transformResponse: function(data) {
          return new Reporting(angular.fromJson(data).reporting);
        }
      },
      query: {
        method: 'GET',
        isArray: true,
        transformResponse: function(data) {
          // Angular resource expects a json array and would return json
          wrapped = angular.fromJson(data);
          return wrapped.reportings;
        }
      }
    });

  // Query that returns a promise instead of an array
  Reporting.getQueryPromise = function(params) {
    deferred = $q.defer();

    Reporting.query(params, function(projects){
      deferred.resolve(projects);
    });

    return deferred.promise;
  };

  // Query returning an array extended with a promise yielding results
  Reporting.getCollection = function(params) {
    queryResults = [];

    queryPromise = Reporting.getQueryPromise(params);
    angular.extend(queryResults, {promise: queryPromise});

    queryPromise.then(function(results){
      angular.forEach(results, function(child){
        queryResults.push(child);
      });
    });

    return queryResults;
  };

  Reporting.prototype.getProjectResource = function() {
    if (this.projectResource === undefined) {
      this.projectResource = Project.get({id: this.getProjectId()});
    }

    return this.projectResource;
  };

  Reporting.prototype.getProject = function() {
   return (this.project !== undefined) ? this.project : null;
  };
  Reporting.prototype.getProjectId = function () {
   return this.project.id;
  };
  Reporting.prototype.getReportingToProject = function () {
   return (this.reporting_to_project !== undefined) ? this.reporting_to_project : null;
  };
  Reporting.prototype.getReportingToProjectId = function () {
   return this.reporting_to_project.id;
  };
  Reporting.prototype.getStatus = function() {
   return (this.reported_project_status !== undefined) ? this.reported_project_status : null;
  };

  return Reporting;
}]);
