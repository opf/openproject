timelinesApp.service('Status', ['$resource', function($resource) {
  Status = {};

  Status.identifier = 'statuses';

  return Status;
}]);
