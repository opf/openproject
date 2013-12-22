timelinesApp.factory('Project', ['$http', '$q', 'APIUrlHelper', function($http, $q, APIUrlHelper) {

  Project = function (data) {
    angular.extend(this, data);
  };

  // Promises based on $http

  Project.buildFromResponse = function(response) {
    return new Project(response.data.project);
  };

  Project.getById = function(id) {
    return $http.get(APIUrlHelper.projectPath(id))
      .then(Project.buildFromResponse);
  };

  Project.collectionFromResponse = function(response) {
    return response.data.projects.map(function(project){
      return new Project(project);
    });
  };

  Project.getCollection = function(params) {
    return $http({method: 'GET', url: APIUrlHelper.projectsPath(), params: params})
      .then(Project.collectionFromResponse);
  };


  Project.prototype.getReportings = function() {
    return Reporting.getCollection(this.identifier, {only_via: 'target'});
  };

  Project.prototype.getReportingProjects = function() {
    return this.getReportings()
      .then(function(reportings){
        return $q.all(
          reportings.map(function(reporting){
            return reporting.getProjectResource();
          })
        );
      });
  };

  Project.prototype.getSelfAndReportingProjects = function () {
    self = this;

    return this.getReportingProjects()
      .then(function(reportingProjects){
        return reportingProjects.concat([self]);
      });
  };


  Project.prototype.getParent = function () {
    return Project.getById(this.parent.id);
  };

  Project.prototype.getChildren = function () {
    return Project.getCollection({parent_id: this.id});
  };

  Project.prototype.getSubProjects = function () {
    var subProjects;

    return this.getChildren()
      .then(function(children) {
        subProjects = children;

        if (!subProjects || subProjects.length === 0) return [];

        $q.all(children.map(function(child){
          return child.getSubProjects();
        })).then(function(projects) {
          angular.forEach(projects.flatten(), function(subProject){
            subProjects.push(subProject);
          });
        });

        return subProjects;
      });
  };

  Project.prototype.getAllPlanningElements = function () {
    return this.getRelatedProjectIds()
      .then(function(projectIds){
        return PlanningElement.getCollection(projectIds);
      });
  };


  return Project;
}]);
