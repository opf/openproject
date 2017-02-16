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

import {opApiModule} from '../../angular-modules';

function apiV3CacheConfig($provide:ng.auto.IProvideService) {
  $provide.decorator('$http', ($delegate:ng.IHttpService, CacheService:op.CacheService) => {
    var $http:ng.IHttpService = $delegate;
    var wrapper = function () {
      var args = arguments;
      var request = args[0];
      var requestable = () => $http.apply($http, args);
      var useCaching = request.cache;
      request.method = request.method.toUpperCase();

      // Override cache values from headers
      if (request.headers && request.headers.caching) {
        useCaching = request.headers.caching.enabled;
      }

      // Do not cache anything but GET
      if (!useCaching || request.method !== 'GET') {
        request.cache = false;
        return requestable();
      }

      if (useCaching) {
        return CacheService.cachedPromise(requestable, request.url);
      }
    };

    // Decorate all fns with our cached wrapper
    Object.keys($http).forEach((key:string) => {
      let prop = ($http as any)[key];
      let fn = function () {
        return prop.apply($http, arguments);
      };

      (wrapper as any)[key] = angular.isFunction(prop) ? fn : prop;
    });

    return wrapper;
  });
}

opApiModule.config(apiV3CacheConfig);
