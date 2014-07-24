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

angular.module('openproject.services')

.service('ActivityService', ['HALAPIResource',
  '$http',
  'PathHelper', function(HALAPIResource, $http, PathHelper){

  var ActivityService = {
    createComment: function(workPackageId, activities, descending, comment) {
      var resource = HALAPIResource.setup(PathHelper.activitiesPath(workPackageId));
      var options = {
        ajax: {
          method: "POST",
          data: { comment: comment }
        }
      };

      return resource.fetch(options).then(function(activity){
        // We are unable to add to the work package's embedded activities directly
        if(activity) {
          if(descending){
            activities.unshift(activity);
          } else {
            activities.push(activity);
          }
          return activity;
        }
      });
    },

    updateComment: function(activityId, comment) {
      var resource = HALAPIResource.setup(PathHelper.activityPath(activityId));
      var options = {
        ajax: {
          method: "PUT",
          data: { comment: comment }
        }
      };

      return resource.fetch(options).then(function(activity){
        return activity;
      });
    }
  }

  return ActivityService;
}]);
