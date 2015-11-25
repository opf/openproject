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

angular
  .module('openproject.workPackages.services')
  .factory('wpActivity', wpActivity);

function wpActivity($filter, ConfigurationService){
  var wpActivity,
      order = ConfigurationService.commentsSortedInDescendingOrder() ? 'desc' : 'asc';

  return wpActivity = {
    activities: [],

    get order() {
      return order;
    },

    aggregateActivities: function(workPackage) {
      var aggregated = [];

      var add = function (data) {
        aggregated.push(data.embedded.elements);

        wpActivity.activities = $filter('orderBy')(
          _.flatten(aggregated), 'props.createdAt', order === 'desc'
        );
      };

      workPackage.links.activities.fetch().then(add);

      if(workPackage.links.revisions) {
        workPackage.links.revisions.fetch().then(add);
      }
    },

    isInitialActivity: function(activity, activityNo) {
      if (activity.props._type.indexOf('Activity') !== 0) {
        return false;
      }

      if (activityNo === 1) {
        return true;
      }

      while (--activityNo > 0) {
        var index = (wpActivity.order === 'desc' ?
                        wpActivity.activities.length - activityNo : activityNo - 1);

        if (wpActivity.activities[index].props._type.indexOf('Activity') === 0) {
          return false;
        }
      }

      return true;
    }
  };
}
