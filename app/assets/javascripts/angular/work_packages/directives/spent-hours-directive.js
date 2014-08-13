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

angular.module('openproject.workPackages.directives')

.directive('spentHours', ['I18n', 'PathHelper', function(I18n, PathHelper) {
  return {
    restrict: 'E',
    templateUrl: '/templates/work_packages/spent_hours.html',
    link: function(scope, element, attributes) {
      scope.spentHours = scope.workPackage.props.spentHours;
      scope.spentHoursUnit = I18n.t('js.label_hours');
      scope.linkToSpentHours = PathHelper.timeEntriesPath(null, scope.workPackage.props.id);

      if (scope.spentHours == 1) {
        scope.spentHoursUnit = I18n.t('js.label_hour');
      }
    }
  };
}]);
