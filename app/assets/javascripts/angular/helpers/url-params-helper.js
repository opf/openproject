//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

angular.module('openproject.helpers')

.service('UrlParamsHelper', ['I18n', function(I18n) {
  var UrlParamsHelper = {
    // copied more or less from angular buildUrl
    buildQueryString: function(params) {
      if (!params) return;

      var parts = [];
      angular.forEach(params, function(value, key) {
        if (!value) return;
        if (!Array.isArray(value)) value = [value];

        angular.forEach(value, function(v) {
          if (v !== null && typeof v === 'object') {
            v = toJson(v);
          }
          parts.push(encodeURIComponent(key) + '=' +
                     encodeURIComponent(v));
        });
      });

      return parts.join('&');
    },

    // TODO: Remove
    encodeQueryForJsonParams: function(query) {
      var paramsData = {};

      if(!!query.projectId) {
        paramsData.p = query.projectId;
      }
      if(!!query.groupBy) {
        paramsData.g = query.groupBy;
      }
      if(!!query.getSortation()) {
        paramsData.t = query.getSortation().encode()
      }
      if(query.filters && query.filters.length) {
        paramsData.f = query.filters.filter(function(filter) {
          return !filter.deactivated;
        })
        .map(function(filter) {
          var filterData = {
            n: filter.name,
            m: filter.modelName,
            o: encodeURIComponent(filter.operator),
            t: filter.type
          };
          if(filter.values) {
            angular.extend(filterData, { v: filter.values })
          }
          return filterData
        });
      }

      return JSON.stringify(paramsData);
    },

    // TODO: Remove
    encodeQueryForNonUpdateJsonParams: function(query) {
      var paramsData = {
        c: query.columns.map(function(column) { return column.name; })
      };
      if(!!query.displaySums) {
        paramsData.s = query.displaySums;
      }

      return JSON.stringify(paramsData);
    },

    encodeQueryAllJsonParams: function(query) {
      var paramsData = {
        c: query.columns.map(function(column) { return column.name; })
      };
      if(!!query.displaySums) {
        paramsData.s = query.displaySums;
      }

      if(!!query.projectId) {
        paramsData.p = query.projectId;
      }
      if(!!query.groupBy) {
        paramsData.g = query.groupBy;
      }
      if(!!query.getSortation()) {
        paramsData.t = query.getSortation().encode()
      }
      if(query.filters && query.filters.length) {
        paramsData.f = query.filters.filter(function(filter) {
          return !filter.deactivated;
        })
        .map(function(filter) {
          var filterData = {
            n: filter.name,
            m: filter.modelName,
            o: encodeURIComponent(filter.operator),
            t: filter.type
          };
          if(filter.values) {
            angular.extend(filterData, { v: filter.values })
          }
          return filterData
        });
      }

      return JSON.stringify(paramsData);
    },

    decodeQueryFromJsonParams: function(queryId, updateJson) {
      var queryData = {};
      if(queryId) {
        queryData.id = queryId;
      }

      if(updateJson) {
        var properties = JSON.parse(updateJson);

        if(!!properties.c) {
          queryData.columns = properties.c.map(function(column) { return { name: column }; });
        }
        if(!!properties.s) {
          queryData.displaySums = properties.s;
        }
        if(!!properties.p) {
          queryData.projectId = properties.p;
        }
        if(!!properties.g) {
          queryData.groupBy = properties.g;
        }
        if(!!properties.f) {
          queryData.filters = properties.f.map(function(urlFilter) {
            var filterData = {
              name: urlFilter.n,
              modelName: urlFilter.m,
              operator: decodeURIComponent(urlFilter.o),
              type: urlFilter.t
            };
            if(urlFilter.v) {
              var vs = Array.isArray(urlFilter.v) ? urlFilter.v : [urlFilter.v];
              angular.extend(filterData, { values: vs });
            }
            return filterData;
          });
        }
        if(!!properties.t) {
          queryData.sortCriteria = properties.t;
        }
      }

      return queryData;
    },

    buildQueryExportOptions: function(query){
      var relativeUrl = "/work_packages";
      if (query.project_id){
        relativeUrl = "/projects/" + query.project_id + relativeUrl;
      }

      return query.exportFormats.map(function(format){
        var url = relativeUrl + "." + format.format + "?" + "set_filter=1&";
        if(format.flags){
          angular.forEach(format.flags, function(flag){
            url = url + flag + "=" + "true";
          });
        }
        url = url + query.getQueryString();

        return {
          identifier: format.identifier,
          label: I18n.t('js.' + format.label_locale),
          format: format.format,
          url: url
        }
      })
    }
  };

  return UrlParamsHelper;
}]);
