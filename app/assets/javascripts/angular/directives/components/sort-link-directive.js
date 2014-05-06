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

angular.module('openproject.uiComponents')

.directive('sortLink', ['I18n', function(I18n) {
  return {
    restrict: 'E',
    transclude: true,
    scope: { sortAttr: '@', sortPredicate: '=' },
    templateUrl: '/templates/components/sort_link.html',
    link: function(scope, element, attrs) {
      var getSortTitle = function() {
        var title = "";
        var attribute = angular.element(element[0]).find('span.ng-scope').text();

        if (scope.sortPredicate.indexOf(scope.sortAttr) >= 0) {
          if (scope.sortPredicate.indexOf('-') >= 0) {
            title = I18n.t('js.label_descending');
          } else {
            title = I18n.t('js.label_ascending');
          }

          title += ' ' + I18n.t('js.label_sorted_by') + ' ' + attribute;
        } else {
          title = I18n.t('js.label_sort_by') + ' ' + attribute;
        }

        return title;
      }

      var getSortCss = function() {
        var sortDirection = 'asc';

        if (scope.sortPredicate.indexOf('-') >= 0) {
          sortDirection = 'desc';
        }

        return sortDirection;
      }

      scope.sortDirection = getSortCss();
      scope.sortTitle = getSortTitle();

      scope.$watch('sortPredicate', function() {
        if (scope.sortPredicate.indexOf(scope.sortAttr) < 0) {
          scope.sortDirection = "";
          scope.sortTitle = getSortTitle();
        }
      });

      scope.sort = function() {
        var sortPrefix = '-';

        if (scope.sortPredicate.indexOf('-') >= 0) {
          sortPrefix = '';
        }

        scope.sortPredicate = sortPrefix + scope.sortAttr;
        scope.sortDirection = getSortCss();
        scope.sortTitle = getSortTitle();
      };
    }
  };
}]);
