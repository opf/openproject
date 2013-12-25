timelinesApp.service('Status', ['$resource', function($resource) {

  Status = function (data) {
     angular.extend(this, data);
  };

  Status.collectionFromResponse = function(response) {
    return response.data.statuses.map(function(status){
      return new Status(status);
    });
  };

  Status.getCollection = function(params) {
    return $http({method: 'GET', url: APIUrlHelper.statussPath(), params: params})
      .then(Status.collectionFromResponse);
  };

  Status.buildFromResponse = function(response) {
    return new Status(response.data.status);
  };

  Status.getById = function(id) {
    return $http.get(APIUrlHelper.statusPath(id))
      .then(Status.buildFromResponse);
  };


  return Status;
}]);
