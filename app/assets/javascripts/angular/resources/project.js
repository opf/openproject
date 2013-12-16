timelinesApp.factory('Project', ['$resource', '$q', 'APIDefaults', function($resource, $q, APIDefaults) {

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

  // Query that returns a promise instead of an array
  Project.getQueryPromise = function(params) {
    deferred = $q.defer();

    Project.query(params, function(projects){
      deferred.resolve(projects);
    });

    return deferred.promise;
  };

  // Query returning an array extended with a promise yielding results
  Project.getCollection = function(params) {
    queryResults = [];

    queryPromise = Project.getQueryPromise(params);
    angular.extend(queryResults, {promise: queryPromise});

    queryPromise.then(function(results){
      angular.forEach(results, function(child){
        queryResults.push(child);
      });
    });

    return queryResults;
  };

  Project.prototype.getReportingsPromise = function() {
    return this.$promise
      .then(function(project){
        return Reporting.getQueryPromise({projectId: project.identifier, only_via: 'target'});
      });
  };

  Project.prototype.getReportingProjectsPromise = function() {
    return this.getReportingsPromise()
      .then(function(reportings) {
        reportingProjects = reportings.map(function(reporting){
          return reporting.getProjectResource();
        });
        return reportingProjects;
      });
  };

  Project.prototype.getSelfAndReportingProjectsPromise = function () {
    projects = [this];

    return this.getReportingProjectsPromise()
      .then(function(reportingProjects){
        angular.forEach(reportingProjects, function(reportingProject){
          projects.push(reportingProject);
        });
        return projects;
      });
  };

  Project.prototype.getSelfAndReportingProjects = function () {
    if (this.selfAndReportingProjects) return this.selfAndReportingProjects;

    selfAndReportingProjects = [];

    this.getSelfAndReportingProjectsPromise()
      .then(function(projects){
        angular.forEach(projects, function(project) {
          selfAndReportingProjects.push(project);
        });
      });

    this.selfAndReportingProjects = selfAndReportingProjects;
    return selfAndReportingProjects;
  };

  Project.prototype.getParent = function() {
    if(!this.parent) return null;

    if(!this.parentProject) {
      this.parentProject = Project.get({id: this.parent.id});
    }
    return this.parentProject;
  };

  Project.prototype.getChildren = function() {
    if (this.children === undefined) {
      this.children = Project.getCollection({parent_id: this.id});
    }
    return this.children;
  };

  Project.prototype.getReportings = function () {
    if (this.reportings) return this.reportings;

    reportings = [];
    project = this;

    this.getReportingsPromise().then(function(results){
      project.reportings = results;
      angular.forEach(results, function(result){
        reportings.push(result);
      });
    });

    return reportings;
  };
  return Project;
}]);
