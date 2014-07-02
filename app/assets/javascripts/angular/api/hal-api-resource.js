 
angular.module('openproject.api')

.factory('HALAPIResource', ['$q', 'PathHelper', function HALAPIResource($q, PathHelper) {
  'use strict';

  var HALAPIResource = {
    configure: function() {
      Hyperagent.configure('defer', $q.defer);
    },

    setup: function(uri) {
      HALAPIResource.configure();
      return new Hyperagent.Resource({
        url: PathHelper.apiPrefixV3 + '/' + uri,
      }); 
    }
  }

  return HALAPIResource;
}]);