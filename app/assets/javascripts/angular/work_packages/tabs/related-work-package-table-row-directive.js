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

// TODO move to UI components
angular.module('openproject.workPackages.tabs')

.directive('relatedWorkPackageTableRow', [
    'I18n',
    'PathHelper',
    'WorkPackagesHelper',
    'ApiHelper',
    'WorkPackageService',
    function(I18n, PathHelper, WorkPackagesHelper, ApiHelper, WorkPackageService) {
  return {
    restrict: 'A',
    link: function(scope) {
      scope.I18n = I18n;
      scope.workPackagePath = PathHelper.staticWorkPackagePath;
      scope.userPath = PathHelper.staticUserPath;
      scope.canDeleteRelation = !!scope.relation.links.remove;

      WorkPackagesHelper.getRelatedWorkPackage(scope.workPackage, scope.relation).then(function(relatedWorkPackage){
        scope.relatedWorkPackage = relatedWorkPackage;
        scope.fullIdentifier = WorkPackagesHelper.getFullIdentifier(relatedWorkPackage);
        scope.state = WorkPackagesHelper.getState(relatedWorkPackage);
      });

      scope.removeRelation = function() {
        WorkPackageService.removeWorkPackageRelation(scope.relation).then(function(response){
          scope.$emit('workPackageRefreshRequired', '');
        }, function(error) {
          ApiHelper.handleError(scope, error);
        });
      };
    }
  };
}]);
