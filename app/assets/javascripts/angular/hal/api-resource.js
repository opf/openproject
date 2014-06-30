 
angular.module('openproject.hal')

.factory('HALAPIResource', function HALAPIResource() {
  'use strict';

  var HALAPIResource = {
    configure: function() {
      Hyperagent.configure('ajax', function ajax(options) {
        // options.dataType = "json";

        return jQuery.ajax(options);
      });
    },

    setup: function(uri) {
      HALAPIResource.configure();
      return new Hyperagent.Resource({
        url: 'http://opapi.apiary-mock.com/' + uri,
      });	
    }
  }

  return HALAPIResource;
});