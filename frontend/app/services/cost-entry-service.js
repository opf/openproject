angular.module('openproject.services')

.service('costEntryService', ['HALAPIResource', function(HALAPIResource) {
  var CostEntryService = {
    getCostEntry: function(url) {
      var resource = HALAPIResource.setup(url);
      return resource.fetch();
    }
  };

  return CostEntryService;
}]);
