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

  Project.prototype.getRelatedProjectIds = function () {
    self = this;

    return this.getReportings()
      .then(function(reportings){
        return [self.id].concat(
          reportings.map(function(reporting){
            return reporting.getProjectId();
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

  Project.prototype.getSubElements = function () {
    self = this;

    var subElements = [];

    return this.getReportingProjects()
      .then(function(reportingProjects){
        angular.forEach(reportingProjects, function(project){
          subElements.push(project);
        });
        return self.getPlanningElements();
      })
      .then(function(planningElements) {
        angular.forEach(planningElements, function(planningElement){
          subElements.push(planningElement);
        });
        return subElements;
      });
  };

  Project.prototype.getPlanningElements = function () {
    self = this;

    return PlanningElement.getCollection([this.id])
      .then(self.augmentWithProjectReference);
  };

  Project.prototype.getAllPlanningElements = function () {
    self = this;

    return this.getRelatedProjectIds()
      .then(PlanningElement.getCollection)
      .then(self.augmentWithProjectReference);
  };

  Project.prototype.augmentWithProjectReference = function(planningElements) {
    return planningElements.map(function(planningElement){
      planningElement.project = self;
      return planningElement;
    });
  };

  return Project;
}]);
