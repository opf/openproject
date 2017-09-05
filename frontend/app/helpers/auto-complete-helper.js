//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

module.exports = function($http, PathHelper) {
  var getAtWhoParametersMentionable = function(at, textarea, projectId) {
    return {
      at: at,
      startWithSpace: false,
      searchKey: 'id_principal',
      displayTpl: '<li data-value="user#${id}">${id}: ${firstName} ${lastName}</li>',
      insertTpl: "user#${id}",
      limit: 10,
      suffix: '',
      textarea: textarea,
      callbacks: {
        remoteFilter: function(query, callback) {
          if (query.length > 0) {
            $http.get(PathHelper.apiv3MentionablePrincipalsPath(projectId, query)).
              success(function(data) {
                // atjs needs the search key to be a string
                principals = data["_embedded"]["elements"]
                for (var i = principals.length - 1; i >= 0; i--) {
                  principals[i]['id_principal'] = principals[i]['id'].toString() + ' ' + principals[i]['firstName'] + ' ' + principals[i]['lastName'];
                }

                if (angular.element(textarea).is(':visible')) {
                  callback(principals);
                }
                else {
                  // discard the results if the textarea is no longer visible,
                  // i.e. nobody cares for the results
                  callback([]);
                }
              });
          }
        },
        sorter: function(query, items, search_key) {
          return items; // we do not sort
        }
      }
    };
  };

  var getAtWhoParametersWPID = function(textarea) {
    var url = PathHelper.workPackageJsonAutoCompletePath();
    return {
      at: '#',
      startWithSpace: true,
      searchKey: 'id_subject',
      displayTpl: '<li data-value="${atwho-at}${id}">${to_s}</li>',
      insertTpl: "${atwho-at}${id}",
      limit: 10,
      textarea: textarea,
      callbacks: {
        remoteFilter: function(query, callback) {
          if (query.length > 0) {
            $http.get(url, { params: { q: query, scope: 'all' } }).
              success(function(data) {
                // atjs needs the search key to be a string
                for (var i = data.length - 1; i >= 0; i--) {
                  data[i]['id_subject'] = data[i]['id'].toString() + ' ' + data[i]['subject'];
                }

                if (angular.element(textarea).is(':visible')) {
                  callback(data);
                }
                else {
                  // discard the results if the textarea is no longer visible,
                  // i.e. nobody cares for the results
                  callback([]);
                }
              });
          }
        },
        sorter: function(query, items, search_key) {
          return items; // we do not sort
        }
      }
    };
  };

  return {
    enableTextareaAutoCompletion: function(textareas, projectId) {
      angular.forEach(textareas, function(textarea) {

        // only activate autocompleter for mentioniong users if the user is
        // in the context of a project and work package.
        if(angular.element('body.controller-work_packages').length > 0 &&
           projectId &&
           projectId.length > 0) {
          angular.element(textarea).atwho(getAtWhoParametersMentionable('@', textarea, projectId));
          angular.element(textarea).atwho(getAtWhoParametersMentionable('user#', textarea, projectId));
        }

        angular.element(textarea).atwho(getAtWhoParametersWPID(textarea));
      });
    }
  };
};
