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

// TODO move to UI components
module.exports = function($timeout) {
  var currentRun;

  return {
    withDelay: function(delay, callback, params) {
      $timeout.cancel(currentRun);

      currentRun = $timeout(function() {
        return callback.apply(this, params);
      }, delay);

      return currentRun;
    },

    /**
     * @name withLoading
     *
     * @description Wraps a data-loading function and manages the loading state within the scope
     * @param {scope} a scope on which an isLoading flag is set
     * @param {function} callback Function returning a promise
     * @param {array} params Params forwarded to the callback
     * @returns {promise} Promise returned by the callback
     */
    withLoading: function(scope, callback, params, errorCallback) {
      scope.isLoading = true;

      return callback.apply(this, params)
        .then(function(results){
          scope.isLoading = false;

          return results;
        }, errorCallback);
    }
  };
};
