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

import {WorkPackageTableHierarchiesService} from '../../wp-fast-table/state/wp-table-hierarchy.service';
import {
  QuerySortByResource,
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC
} from '../../api/api-v3/hal-resources/query-sort-by-resource.service';
import {WorkPackageTableSortBy} from '../../wp-fast-table/wp-table-sort-by';
import {WorkPackageTableSortByService} from '../../wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableGroupByService} from './../../wp-fast-table/state/wp-table-group-by.service';
import {scopeDestroyed$} from '../../../helpers/angular-rx-utils';
import {WorkPackageTableRelationColumnsService} from '../../wp-fast-table/state/wp-table-relation-columns.service';
import {RelationQueryColumn, TypeRelationQueryColumn} from '../../wp-query/query-column';

angular
  .module('openproject.workPackages.directives')
  .directive('sortHeader', sortHeader);

function sortHeader(wpTableHierarchies:WorkPackageTableHierarchiesService,
                    wpTableSortBy:WorkPackageTableSortByService,
                    wpTableGroupBy:WorkPackageTableGroupByService,
                    wpTableRelationColumns:WorkPackageTableRelationColumnsService,
                    I18n:op.I18n) {
  return {
    restrict: 'A',
    templateUrl: '/components/wp-table/sort-header/sort-header.directive.html',

    scope: {
      column: '=headerColumn',
      locale: '='
    },

    link: function (scope:any, element:ng.IAugmentedJQuery) {
      wpTableSortBy.onReadyWithAvailable()
        .takeUntil(scopeDestroyed$(scope))
        .subscribe(() => {
          let latestSortElement = wpTableSortBy.currentSortBys[0];

          if (!latestSortElement || scope.column.$href !== latestSortElement.column.$href) {
            scope.currentSortDirection = null;
          } else {
            scope.currentSortDirection = latestSortElement.direction;
          }

          setFullTitleAndSummary();

          scope.sortable = wpTableSortBy.isSortable(scope.column);

          scope.directionClass = directionClass();
        });

      scope.$watch('currentSortDirection', setActiveColumnClass);

      scope.text = {
        toggleHierarchy: I18n.t('js.work_packages.hierarchy.show'),
        openMenu: I18n.t('js.label_open_menu')
      };

      // Place the hierarchy icon left to the subject column
      scope.isHierarchyColumn = scope.column.id === 'subject';

      if (scope.isHierarchyColumn) {
        scope.columnType = 'hierarchy';
      } else if (wpTableRelationColumns.relationColumnType(scope.column) === 'toType') {
        scope.columnType = 'relation';
        scope.columnName = (scope.column as TypeRelationQueryColumn).type.name;
      } else if (wpTableRelationColumns.relationColumnType(scope.column) === 'ofType') {
        scope.columnType = 'relation';
        scope.columnName = I18n.t('js.relation_labels.' + (scope.column as RelationQueryColumn).relationType);
      }

      function setHierarchyIcon() {
        if (wpTableHierarchies.isEnabled) {
          scope.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.hide');
          scope.hierarchyIcon = 'icon-hierarchy';
        }
        else {
          scope.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.show');
          scope.hierarchyIcon = 'icon-no-hierarchy';
        }
      }

      if (scope.isHierarchyColumn) {
        scope.hierarchyIcon = 'icon-hierarchy';
        scope.isHierarchyDisabled = wpTableGroupBy.isEnabled;

        // Disable hierarchy mode when group by is active
        wpTableGroupBy.observeOnScope(scope).subscribe(() => {
          scope.isHierarchyDisabled = wpTableGroupBy.isEnabled;
        });

        // Update hierarchy icon when updated elsewhere
        wpTableHierarchies.observeOnScope(scope).subscribe(() => {
          setHierarchyIcon();
        });

        // Set initial icon
        setHierarchyIcon();

        // Hierarchy toggle handler
        scope.toggleHierarchy = function (evt:JQueryEventObject) {
          wpTableHierarchies.toggleState();
          setHierarchyIcon();

          evt.stopPropagation();
          return false;
        };
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

        if (scope.currentSortDirection) {
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
