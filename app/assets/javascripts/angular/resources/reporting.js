timelinesApp.service('Reporting', ['$resource', 'Project', 'Status', function($resource, Project, Status) {

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
