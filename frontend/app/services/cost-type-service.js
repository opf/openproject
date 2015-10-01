angular.module('openproject.services')

.service('CostTypeService', ['HALAPIResource', function(HALAPIResource) {
  var CostTypeService = {
    getCostType: function(url) {
      var resource = HALAPIResource.setup(url, { fullyQualified: true });
      return resource.fetch();
    }
  };

  return CostTypeService;
}]);
