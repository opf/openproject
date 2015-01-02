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

module.exports = function($http) {
  var getAtWhoParameters = function(url) {
    return {
      at: '#',
      start_with_space: false,
      search_key: 'id_subject',
      tpl: '<li data-value="${atwho-at}${id}">${to_s}</li>',
      limit: 10,
      callbacks: {
        remote_filter: function(query, callback) {
          if (query.length > 0) {
            $http.get(url, { params: { q: query, scope: 'all' } }).
              success(function(data) {
                // atjs needs the search key to be a string
                for (var i = data.length - 1; i >= 0; i--) {
                  data[i]['id_subject'] = data[i]['id'].toString() + ' ' + data[i]['subject'];
                }
                callback(data);
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
    enableTextareaAutoCompletion: function(textareas) {
      angular.forEach(textareas, function(textarea) {
        var url = angular.element(textarea).data('wp_autocomplete_url');

        if (url !== undefined && url.length > 0) {
          angular.element(textarea).atwho(getAtWhoParameters(url));
        }
      });
    }
  };
};
