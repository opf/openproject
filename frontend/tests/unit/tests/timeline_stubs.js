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

/*jshint expr: true*/

function nop() {}

var modalHelperInstance = {
  setupTimeline: nop
};

var possibleData = {
  projects: [{
      "id":1,
      "name":"Eltern",
      "identifier":"eltern-1",
      "description":"",
      "project_type_id":null,
      "parent_id":null,
      "responsible_id":null,
      "type_ids":[1,2,3,4,5,6],
      "created_on":"2013-11-04T14:49:36Z",
      "updated_on":"2013-11-04T14:49:36Z"
    }]
};

var I18n = { t: function() {} };

// Timeline.TimelineLoader.QueueingLoader.prototype.loadElement = function (identifier, element) {
//   this.loading[identifier] = element;
//
//   var that = this;
//
//   window.setTimeout(function () {
//       var readFrom = element.context.readFrom || element.context.storeIn  || identifier;
//
//       var data = {};
//       data[readFrom] = possibleData[readFrom] || [];
//
//       delete that.loading[identifier];
//
//       jQuery(that).trigger('success', {
//         identifier : identifier,
//         context    : element.context,
//         data       : data
//       });
//
//       that.onComplete();
//      }
//   );
// };
