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

function wpActivity($filter, $q, ConfigurationService){
  var wpActivity,
      order = ConfigurationService.commentsSortedInDescendingOrder() ? 'desc' : 'asc',
      activities = [];

  return wpActivity = {
    get activities() {
      return activities;
    },

    get order() {
      return order;
    },

    aggregateActivities: function (workPackage) {
      var aggregated = [], promises = [];

      var add = function (data) {
        aggregated.push(data.embedded.elements);
      };

      promises.push(workPackage.links.activities.fetch().then(add));

      if (workPackage.links.revisions) {
        promises.push(workPackage.links.revisions.fetch().then(add));
      }

      return $q.all(promises).then(function () {
        activities.length = 0;
        activities.push.apply(activities, $filter('orderBy')(
          _.flatten(aggregated), 'props.createdAt', order === 'desc'
        ));
      });
    },

    info: function (activity, index) {
      var activityDate = function (activity) {
        return $filter('date')(activity.props.createdAt, 'longDate')
      };

      return {
        get number() {
          return order === 'desc' && activities.length - index || index + 1;
        },

        get date() {
          return activityDate(activity);
        },

        get dateOfPrevious() {
          if (index > 0) {
            return activityDate(activities[index - 1])
          }
        },

        get isNextDate() {
          return this.date !== this.dateOfPrevious;
        },

        get anchor() {
          return 'note-' + this.number;
        },

        get isInitial() {
          var activityNo = this.number;

          if (activity.props._type.indexOf('Activity') !== 0) {
            return false;
          }

          if (activityNo === 1) {
            return true;
          }

          while (--activityNo > 0) {
            var index =
                  wpActivity.order === 'desc' ? activities.length - activityNo : activityNo - 1;

            if (activities[index].props._type.indexOf('Activity') === 0) {
              return false;
            }
          }

          return true;
        }
      };
    }
  };
}
