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

import {AfterViewInit, Component, ElementRef, Inject, Input, OnDestroy} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC
} from 'core-components/api/api-v3/hal-resources/query-sort-by-resource.service';
import {RelationQueryColumn, TypeRelationQueryColumn} from 'core-components/wp-query/query-column';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {WorkPackageTableHierarchiesService} from '../../wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableRelationColumnsService} from '../../wp-fast-table/state/wp-table-relation-columns.service';
import {WorkPackageTableSortByService} from '../../wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableGroupByService} from './../../wp-fast-table/state/wp-table-group-by.service';


@Component({
  selector: 'sortHeader',
  template: require('!!raw-loader!./sort-header.directive.html')
})
export class SortHeaderDirective implements OnDestroy, AfterViewInit {

  @Input() headerColumn:any;

  @Input() locale:string;

  sortable:boolean;

  directionClass:string;

  text:{ toggleHierarchy:string, openMenu:string } = {
    toggleHierarchy: '',
    openMenu: ''
  };

  isHierarchyColumn:boolean;

  columnType:'hierarchy' | 'relation';

  columnName:string;

  hierarchyIcon:string;

  isHierarchyDisabled:boolean;

  private element:JQuery;

  private currentSortDirection:any;

  constructor(private wpTableHierarchies:WorkPackageTableHierarchiesService,
              private wpTableSortBy:WorkPackageTableSortByService,
              private wpTableGroupBy:WorkPackageTableGroupByService,
              private wpTableRelationColumns:WorkPackageTableRelationColumnsService,
              private elementRef:ElementRef,
              @Inject(I18nToken) private I18n:op.I18n) {
  }

  // noinspection TsLint
  ngOnDestroy():void {
  }

  ngAfterViewInit():void {
    this.element = jQuery(this.elementRef.nativeElement);

    this.wpTableSortBy.onReadyWithAvailable()
      .takeUntil(componentDestroyed(this))
      .subscribe(() => {
        let latestSortElement = this.wpTableSortBy.currentSortBys[0];

        if (!latestSortElement || this.headerColumn.$href !== latestSortElement.column.$href) {
          this.currentSortDirection = null;
        } else {
          this.currentSortDirection = latestSortElement.direction;
        }

        this.setFullTitleAndSummary();

        this.sortable = this.wpTableSortBy.isSortable(this.headerColumn);

        this.directionClass = this.getDirectionClass();
      });

    // TODO
    //scope.$watch('currentSortDirection', setActiveColumnClass);

    this.text = {
      toggleHierarchy: I18n.t('js.work_packages.hierarchy.show'),
      openMenu: I18n.t('js.label_open_menu')
    };

    // Place the hierarchy icon left to the subject column
    this.isHierarchyColumn = this.headerColumn.id === 'subject';

    if (this.isHierarchyColumn) {
      this.columnType = 'hierarchy';
    } else if (this.wpTableRelationColumns.relationColumnType(this.headerColumn) === 'toType') {
      this.columnType = 'relation';
      this.columnName = (this.headerColumn as TypeRelationQueryColumn).type.name;
    } else if (this.wpTableRelationColumns.relationColumnType(this.headerColumn) === 'ofType') {
      this.columnType = 'relation';
      this.columnName = I18n.t('js.relation_labels.' + (this.headerColumn as RelationQueryColumn).relationType);
    }


    if (this.isHierarchyColumn) {
      this.hierarchyIcon = 'icon-hierarchy';
      this.isHierarchyDisabled = this.wpTableGroupBy.isEnabled;

      // Disable hierarchy mode when group by is active
      this.wpTableGroupBy.state.values$()
        .takeUntil(componentDestroyed(this))
        .subscribe(() => {
          this.isHierarchyDisabled = this.wpTableGroupBy.isEnabled;
        });

      // Update hierarchy icon when updated elsewhere
      this.wpTableHierarchies.state.values$()
        .takeUntil(componentDestroyed(this))
        .subscribe(() => {
          this.setHierarchyIcon();
        });

      // Set initial icon
      this.setHierarchyIcon();
    }
  }

  toggleHierarchy(evt:JQueryEventObject) {
    this.wpTableHierarchies.toggleState();
    this.setHierarchyIcon();

    evt.stopPropagation();
    return false;
  }

  setHierarchyIcon() {
    if (this.wpTableHierarchies.isEnabled) {
      this.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.hide');
      this.hierarchyIcon = 'icon-hierarchy';
    }
    else {
      this.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.show');
      this.hierarchyIcon = 'icon-no-hierarchy';
    }
  }

  setFullTitleAndSummary() {
    // TODO unused?
    //this.fullTitle = this.headerTitle;

    // if (this.currentSortDirection) {
    //   var ascending = this.currentSortDirection.$href === QUERY_SORT_BY_ASC;
    //   var summaryContent = [
    //     ascending ? I18n.t('js.label_ascending') : I18n.t('js.label_descending'),
    //     I18n.t('js.label_sorted_by'),
    //     this.headerTitle + '.'
    //   ];
    //
    //   jQuery('#wp-table-sort-summary').text(summaryContent.join(' '));
    // }
  }

  private getDirectionClass():string {
    if (!this.currentSortDirection) {
      return '';
    }

    switch (this.currentSortDirection.$href) {
      case QUERY_SORT_BY_ASC:
        return 'asc';
      case QUERY_SORT_BY_DESC:
        return 'desc';
      default:
        return '';
    }
  }

  setActiveColumnClass() {
    this.element.toggleClass('active-column', !!this.currentSortDirection);
  }

}

// angular
//   .module('openproject.workPackages.directives')
//   .directive('sortHeader', sortHeader);
//
// function sortHeader(wpTableHierarchies:WorkPackageTableHierarchiesService,
//                     wpTableSortBy:WorkPackageTableSortByService,
//                     wpTableGroupBy:WorkPackageTableGroupByService,
//                     wpTableRelationColumns:WorkPackageTableRelationColumnsService,
//                     I18n:op.I18n) {
//   return {
//     restrict: 'A',
//     templateUrl: '/components/wp-table/sort-header/sort-header.directive.html',
//
//     scope: {
//       column: '=headerColumn',
//       locale: '='
//     },
//
//     link: function(scope:any, element:ng.IAugmentedJQuery) {
//     }
//   };
// }
//


