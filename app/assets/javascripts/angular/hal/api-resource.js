 
angular.module('openproject.hal')

.factory('HALAPIResource', ['$q', function HALAPIResource($q) {
  'use strict';

  var HALAPIResource = {
    configure: function() {
      Hyperagent.configure('defer', $q.defer);
    },

    setup: function(uri) {
      HALAPIResource.configure();
      return new Hyperagent.Resource({
        url: 'http://opapi.apiary-mock.com/' + uri,
      }); 
    }
  }

  return HALAPIResource;
}]);