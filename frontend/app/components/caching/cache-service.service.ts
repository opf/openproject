//-- copyright
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
//++

function CacheService($q:ng.IQService, CacheFactory:any) {

  // Temporary storage for currently resolving promises
  var _promises:{[key:string]: ng.IPromise<any>} = {};

  // Global switch to disable all caches
  var disabled = false;

  var CacheService = {

    temporaryCache: function() {
      return CacheService.customCache('openproject-session_cache', {
        maxAge: 10 * 60 * 1000, // 10 mins
        storageMode: 'sessionStorage'
      });
    },

    localStorage: function() {
      return CacheService.customCache('openproject-local_storage_cache', {
        storageMode: 'localStorage'
      });
    },

    memoryStorage: function() {
      return CacheService.customCache('openproject-memory_storage_cache', {
        storageMode: 'memory'
      });
    },

    customCache: function(identifier:string, params:any) {
      var _cache = CacheFactory.get(identifier);

      if (!_cache) {
        _cache = CacheFactory(identifier, params);
      }

      if (disabled) {
        _cache.disable();
      }

      return _cache;
    },

    isCacheDisabled: function() {
      return disabled;
    },

    enableCaching: function() {
      disabled = false;
    },

    disableCaching: function() {
      disabled = true;
    },

    clearPromisedKey: function(key:string, options:any) {
      options = options || {};
      var cache = options.cache || CacheService.memoryStorage();
      cache.remove(key);
    },

    cachedPromise: function(promiseFn:() => ng.IPromise<any>, key:string, options:any) {
      options = options || {};
      var cache = options.cache || CacheService.memoryStorage();
      var force = options.force || false;
      var deferred = $q.defer();
      var cachedValue, promise;

      // Return early when frontend caching is not desired
      if (cache.disabled) {
        return promiseFn();
      }

      // Got the result directly? Great.
      cachedValue = cache.get(key);
      if (cachedValue && !force) {
        deferred.resolve(cachedValue);
        return deferred.promise;
      }

      // Return an existing promise if it exists
      // Avoids intermittent requests while a first
      // is already underway.
      if (_promises[key]) {
        return _promises[key];
      }

      // Call now to retrieve promise
      promise = promiseFn();
      promise
        .then(data => {
          cache.put(key, data);
          deferred.resolve(data);
        })
        .catch(error => {
          deferred.reject(error);
          cache.remove(key);
        })
        .finally(() => delete _promises[key]);

      _promises[key] = deferred.promise;
      return deferred.promise;
    },
  };

  return CacheService;
}


angular
  .module('openproject.services')
  .factory('CacheService', CacheService);

