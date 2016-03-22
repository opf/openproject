// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

function apiV3CacheConfig($provide) {

  // Add caching wrapper around $http using angular-cache
  $provide.decorator('$http', function($delegate, CacheService) {
    var $http = $delegate;
    var wrapper = function() {
      var params = arguments;
      var request = arguments[0];
      var requestable = () => $http.apply($http, params);
      var useCaching = request.cache || true;
      var cacheOptions;

      // Override cache values from headers
      if (request.headers && request.headers.caching) {
        cacheOptions = request.headers.caching;
        useCaching = cacheOptions.enabled;
        delete request.headers.caching;
      }


      // Do not cache anything but GET coming from Restangualr
      if (!useCaching || (request.method && request.method !== 'GET')) {
        request.cache = false;
        return requestable();
      }

      if (useCaching) {
        return CacheService.cachedPromise(requestable, request.url);
      }
    };

    Object.keys($http).forEach(function(key) {
      // Decorate all fns with our cached wrapper
      if (typeof $http[key] === 'function') {
        wrapper[key] = function() {
          return $http[key].apply($http, arguments);
        };
      } else {
        wrapper[key] = $http[key];
      }
    });

    return wrapper;
  });

}

angular
  .module('openproject.api')
  .config(apiV3CacheConfig);
