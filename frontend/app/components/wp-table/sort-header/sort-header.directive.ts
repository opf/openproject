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

import {WorkPackageTableHierarchyService} from '../../wp-fast-table/state/wp-table-hierarchy.service';
import {
  QuerySortByResource,
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC
} from '../../api/api-v3/hal-resources/query-sort-by-resource.service';
import {WorkPackageTableSortBy} from '../../wp-fast-table/wp-table-sort-by';
import {WorkPackageTableSortByService} from '../../wp-fast-table/state/wp-table-sort-by.service';

angular
  .module('openproject.workPackages.directives')
  .directive('sortHeader', sortHeader);

function sortHeader(wpTableHierarchy: WorkPackageTableHierarchyService,
                    wpTableSortBy: WorkPackageTableSortByService,
                    I18n: op.I18n) {
  return {
    restrict: 'A',
    templateUrl: '/components/wp-table/sort-header/sort-header.directive.html',

    scope: {
      column: '=headerColumn',
      locale: '='
    },

    link: function(scope: any, element: ng.IAugmentedJQuery) {
      wpTableSortBy.observeOnScope(scope).subscribe((sortBy:WorkPackageTableSortBy) => {
        let latestSortElement = sortBy.current[0];

        if (!latestSortElement || scope.column.$href !== latestSortElement.column.$href) {
          scope.currentSortDirection = null;
        } else {
          scope.currentSortDirection = latestSortElement.direction;
        }

        setFullTitleAndSummary();

        scope.sortable = sortBy.isSortable(scope.column);

        scope.directionClass = directionClass();
      });

      scope.$watch('currentSortDirection', setActiveColumnClass);

      scope.text = {
        toggleHierarchy: I18n.t('js.work_packages.hierarchy.show'),
        openMenu: I18n.t('js.label_open_menu')
      };

      // Place the hierarchy icon left to the subject column
      scope.isHierarchyColumn = scope.column.id === 'subject';
      scope.hierarchyIcon = 'icon-hierarchy';

      scope.toggleHierarchy = function(evt:JQueryEventObject) {
        wpTableHierarchy.toggleState();

        if(wpTableHierarchy.isEnabled) {
          scope.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.hide');
          scope.hierarchyIcon = 'icon-no-hierarchy';
        }
        else {
          scope.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.show');;
          scope.hierarchyIcon = 'icon-hierarchy';
        }

        evt.stopPropagation();
        return false;
      }

      function directionClass() {
        if (!scope.currentSortDirection) {
          return '';
        }

        switch (scope.currentSortDirection.$href) {
          case QUERY_SORT_BY_ASC:
            return 'asc';
          case QUERY_SORT_BY_DESC:
            return 'desc';
          default:
            return '';
        }
      }

      function setFullTitleAndSummary() {
        scope.fullTitle = scope.headerTitle;

        if(scope.currentSortDirection) {
          var ascending = scope.currentSortDirection.$href === QUERY_SORT_BY_ASC;
          var summaryContent = [
            ascending ? I18n.t('js.label_ascending') : I18n.t('js.label_descending'),
            I18n.t('js.label_sorted_by'),
            scope.headerTitle + '.'
          ]

          jQuery('#wp-table-sort-summary').text(summaryContent.join(" "));
        }
      }

      function setActiveColumnClass() {
        element.toggleClass('active-column', !!scope.currentSortDirection);
      }
    }
  };
}
