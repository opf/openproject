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
  var reverse = ConfigurationService.commentsSortedInDescendingOrder(),
      order = reverse ? 'desc' : 'asc',
      activities = [];

  return {
    get activities() {
      return activities;
    },

    get order() {
      return order;
    },

    get isReversed() {
      return reverse;
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
          _.flatten(aggregated), 'props.createdAt', reverse
        ));
      });
    },

    info: function (activity, index) {
      var activityDate = function (activity) {
        return $filter('date')(activity.props.createdAt, 'longDate')
      };

      var orderedIndex = function(idx, forceReverse) {
        return (forceReverse || reverse) && activities.length - idx || idx + 1;
      };

      return {
        number: function(forceReverse) {
          return orderedIndex(index, forceReverse);
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

        isInitial: function(forceReverse) {
          var activityNo = this.number(forceReverse);

          if (activity.props._type.indexOf('Activity') !== 0) {
            return false;
          }

          if (activityNo === 1) {
            return true;
          }

          while (--activityNo > 0) {
            var idx = orderedIndex(activityNo, forceReverse) - 1;
            if (activities[idx].props._type.indexOf('Activity') === 0) {
              return false;
            }
          }

          return true;
        }
      };
    }
  };
}
