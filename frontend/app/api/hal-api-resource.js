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

require('hyperagent');

module.exports = function HALAPIResource($timeout, $q, PathHelper) {
  'use strict';

  var HALAPIResource = {
    configure: function() {
      Hyperagent.configure('ajax', function(settings) {
        var deferred = $q.defer(),
            resolve = settings.success,
            reject = settings.error;

        settings.success = deferred.resolve;
        settings.reject = deferred.reject;

        deferred.promise.then(function(response) {
          $timeout(function() { resolve(response); });
        }, function(reason) {
          $timeout(function() { reject(reason); });
        });

        return jQuery.ajax(settings);
      });
      Hyperagent.configure('defer', $q.defer);
      // keep this if you want null values to not be overwritten by
      // Hyperagent.js miniscore
      // this weird line replaces HA miniscore with normal underscore
      // Freud would be happy with what ('_', _) reminds me of
      Hyperagent.configure('_', _);
    },

    setup: function(uri) {
      HALAPIResource.configure();
      return new Hyperagent.Resource({
        url: PathHelper.appBasePath + PathHelper.apiV3 + '/' + uri,
      });
    }
  };

  return HALAPIResource;
};
