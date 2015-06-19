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
module.exports = function($http, PathHelper) {
  return {
    restrict: 'E',
    templateUrl: '/templates/work_packages/tabs/_add_work_package_relation.html',
    link: function(scope, element, attributes) {
      scope.relationToAddId = null;
      scope.autocompleteWorkPackages = function(term) {
        if (!term) {
          return;
        }
        var params = {
          q: term,
          scope: 'all',
          escape: false,
          id: scope.handler.workPackage.props.id,
          'project_id': scope.handler.workPackage.embedded.project.props.id
        };
        return $http({
          method: 'GET',
          url: URI(PathHelper.workPackageJsonAutoCompletePath())
            .search(params)
            .toString()
        }).then(function(response) {
          scope.options = response.data;
        });
      }
    }
  };
};
