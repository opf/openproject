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
  .module('openproject.workPackages.directives')
  .directive('sortHeader', sortHeader);

function sortHeader(){
  return {
    restrict: 'A',
    templateUrl: '/components/wp-table/sort-header/sort-header.directive.html',

    scope: {
      query: '=',
      headerName: '=',
      headerTitle: '=',
      sortable: '=',
      locale: '='
    },

    link: function(scope, element) {
      scope.$watch('query.sortation.sortElements', function(sortElements){
        var latestSortElement = sortElements[0];

        if (scope.headerName !== latestSortElement.field) {
          scope.currentSortDirection = null;
        } else {
          scope.currentSortDirection = latestSortElement.direction;
        }

        setFullTitleAndSummary();
      }, true);

      scope.$watch('currentSortDirection', setActiveColumnClass);

      function setFullTitleAndSummary() {
        scope.fullTitle = scope.headerTitle;

        if(scope.currentSortDirection) {
          var ascending = scope.currentSortDirection === 'asc';
          var summaryContent = [
            ascending ? I18n.t('js.label_ascending') : I18n.t('js.label_descending'),
            I18n.t('js.label_sorted_by'),
            scope.headerTitle + '.',
            I18n.t('js.work_packages.table.text_sort_hint')
          ];

          jQuery('#wp-table-sort-summary').text(summaryContent.join(" "));
        }
      }

      function setActiveColumnClass() {
        element.toggleClass('active-column', !!scope.currentSortDirection);
      }
    }
  };
}
