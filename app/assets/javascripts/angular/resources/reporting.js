timelinesApp.service('Reporting', ['$http', 'APIUrlHelper', 'Project', 'Status', function($http, APIUrlHelper, Project, Status) {

  Reporting = function (data) {
     angular.extend(this, data);
  };

  Reporting.collectionFromResponse = function(response) {
    return response.data.reportings.map(function(reporting){
      return new Reporting(reporting);
    });
  };

  Reporting.getCollection = function(projectId, params) {
    return $http({method: 'GET', url: APIUrlHelper.projectReportingsPath(projectId), params: params})
      .then(Reporting.collectionFromResponse);
  };

  Reporting.prototype.getProjectResource = function() {
    return Project.getById(this.getProjectId());
  };

  // API data accessors

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
