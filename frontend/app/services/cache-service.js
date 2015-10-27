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

module.exports = function(HALAPIResource,
                          $http,
                          $q,
                          CacheFactory) {

  // Temporary storage for currently resolving promises
  var _promises = {};

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

    customCache: function(identifier, params) {
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

    loadResource: function(resource, force) {
      var key = resource.props.href,
        cache = CacheService.temporaryCache(),
        cachedValue,
        _fetchResource = function() {
          var deferred = $q.defer();

          resource.fetch().then(function(data) {
            cache.put(key, data);
            deferred.resolve(data);
          }, function() {
            deferred.reject();
            cache.remove(key);
          });

          return deferred.promise;
        };

      // Return early when frontend caching is not desired
      if (cache.disabled) {
        return _fetchResource();
      }

      // Got the result directly? Great.
      cachedValue = cache.get(key);
      if (cachedValue && !force) {
        var deferred = $q.defer();
        deferred.resolve(cachedValue);
        return deferred.promise;
      }

      // Return an existing promise if it exists
      // Avoids intermittent requests while a first
      // is already underway.
      if (_promises[key]) {
        return _promises[key];
      }

      var promise = _fetchResource();
      _promises[key] = promise;
      return promise;
    }
  };

  return CacheService;
};
