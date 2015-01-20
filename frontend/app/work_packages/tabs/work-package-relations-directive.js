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

module.exports = function(I18n, WorkPackagesHelper, $timeout) {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      title: '@',
      handler: '=',
      btnTitle: '@buttonTitle',
      btnIcon: '@buttonIcon',
      isSingletonRelation: '@singletonRelation'
    },
    templateUrl: '/templates/work_packages/tabs/_work_package_relations.html',
    link: function(scope, element, attrs) {
      scope.I18n = I18n;
      scope.focusElementIndex = -2;

      var setExpandState = function() {
        scope.expand = !scope.handler.isEmpty();
      };

      scope.$watch('handler', function() {
        if (scope.handler) {
          scope.workPackage = scope.handler.workPackage;

          setExpandState();
          scope.relationsCount = scope.handler.getCount();

          if (scope.handler.applyCustomExtensions) {
            $timeout(function() {
              scope.handler.applyCustomExtensions();
            });
          }
        }
      });

      scope.$watch('expand', function(newVal, oldVal) {
        scope.stateClass = WorkPackagesHelper.collapseStateIcon(newVal);
      });

      scope.toggleExpand = function() {
        scope.expand = !scope.expand;
      };

      scope.isFocused = function(index) {
        return index == scope.focusElementIndex;
      };

      scope.updateFocus = function(index) {
        var length = scope.handler.relations.length;

        if (length == 0) {
          scope.focusElementIndex = -1;
        } else {
          scope.focusElementIndex = (index < length) ? index : length - 1;
        }

        $timeout(function() {
          scope.$broadcast('updateFocus');
        });
      };
    }
  };
};
