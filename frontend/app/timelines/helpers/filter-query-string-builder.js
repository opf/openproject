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

// ╭───────────────────────────────────────────────────────────────╮
// │  _____ _                _ _                                   │
// │ |_   _(_)_ __ ___   ___| (_)_ __   ___  ___                   │
// │   | | | | '_ ` _ \ / _ \ | | '_ \ / _ \/ __|                  │
// │   | | | | | | | | |  __/ | | | | |  __/\__ \                  │
// │   |_| |_|_| |_| |_|\___|_|_|_| |_|\___||___/                  │
// ├───────────────────────────────────────────────────────────────┤
// │ Javascript library that fetches and plots timelines for the   │
// │ OpenProject timelines module.                                 │
// ╰───────────────────────────────────────────────────────────────╯

module.exports = function() {

  var FilterQueryStringBuilder = (function() {

    /**
     * FilterQueryStringBuilder
     *
     * Simple serializer of query strings that satisfies OpenProject's filter
     * API. Transforms hashes of desired filterings into the proper query strings.
     *
     * Examples:
     *
     *   fqsb = (new FilterQueryStringBuilder({
     *     'type_id': [4, 5]
     *   })).build(
     *     '/api/v2/projects/sample_project/planning_elements.json'
     *   );
     *
     *   => /api/v2/projects/sample_project/planning_elements.json?f[]=type_id&op[type_id]==&v[type_id][]=4&v[type_id][]=5
     *
     *   fqsb = (new FilterQueryStringBuilder())
     *     .filter({ 'type_id': [4, 5] })
     *     .append({ 'at_time': 1380795754 })
     *     .build( '/api/v2/projects/sample_project/planning_elements.json' );
     *
     *   => /api/v2/projects/sample_project/planning_elements.json?f[]=type_id&op[type_id]==&v[type_id][]=4&v[type_id][]=5&at_time=1380795754
     */
    var FilterQueryStringBuilder = function (filterHash) {
      this.filterHash = filterHash || {};
      this.paramsHash = {};
    };

    FilterQueryStringBuilder.prototype.filter = function(filters) {
      this.filterHash = jQuery.extend({}, this.filterHash, filters);
      return this;
    };

    FilterQueryStringBuilder.prototype.append = function(addition) {
      this.paramsHash = jQuery.extend({}, this.paramsHash, addition);
      return this;
    };

    FilterQueryStringBuilder.prototype.buildMetaDataForKey = function(key) {
      this.queryStringParts.push({name: 'f[]', value: key},
                                 {name: 'op[' + key + ']', value: '='});
    };

    FilterQueryStringBuilder.prototype.prepareFilterDataForKeyAndValue = function(key, value) {
      this.queryStringParts.push({name: 'v[' + key + '][]', value: value});
    };

    FilterQueryStringBuilder.prototype.prepareAdditionalQueryData = function(key, value) {
      this.queryStringParts.push({name: key, value: value});
    };

    FilterQueryStringBuilder.prototype.prepareFilterDataForKeyAndArrayOfValues = function(key, value) {
      jQuery.each(value, jQuery.proxy( function(i, e) {
         this.prepareFilterDataForKeyAndValue(key, e);
      }, this));
    };

    FilterQueryStringBuilder.prototype.buildFilterDataForValue = function(key, value) {
      if (Array.isArray(value)) {
        this.prepareFilterDataForKeyAndArrayOfValues(key, value);
      } else {
        this.prepareFilterDataForKeyAndValue(key, value);
      }
    };

    FilterQueryStringBuilder.prototype.registerKeyAndValue = function(key, value) {
      this.buildMetaDataForKey(key);
      this.buildFilterDataForValue(key, value);
    };

    FilterQueryStringBuilder.prototype.prepareQueryStringParts = function() {
      this.queryStringParts = [];
      jQuery.each(this.filterHash, jQuery.proxy(this.registerKeyAndValue, this));
      jQuery.each(this.paramsHash, jQuery.proxy(this.prepareAdditionalQueryData, this));
    };

    FilterQueryStringBuilder.prototype.buildQueryStringFromQueryStringParts = function(url) {
      return jQuery.map(this.queryStringParts, function(e, i) {
        return e.name + "=" + encodeURIComponent(e.value);
      }).join('&');
    };

    FilterQueryStringBuilder.prototype.buildUrlFromQueryStringParts = function(url) {
      var resultUrl = url;
      resultUrl += "?";
      resultUrl += this.buildQueryStringFromQueryStringParts();
      return resultUrl;
    };

    FilterQueryStringBuilder.prototype.build = function(url) {
      this.prepareQueryStringParts();
      return this.buildUrlFromQueryStringParts(url);
    };

    return FilterQueryStringBuilder;
  })();

  return FilterQueryStringBuilder;
};
