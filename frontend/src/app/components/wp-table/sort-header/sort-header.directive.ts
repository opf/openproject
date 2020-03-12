// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {AfterViewInit, ChangeDetectorRef, Component, ElementRef, Input} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {RelationQueryColumn, TypeRelationQueryColumn} from 'core-components/wp-query/query-column';
import {WorkPackageTable} from 'core-components/wp-fast-table/wp-fast-table';
import {QUERY_SORT_BY_ASC, QUERY_SORT_BY_DESC} from 'core-app/modules/hal/resources/query-sort-by-resource';
import {WorkPackageViewHierarchiesService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import {WorkPackageViewSortByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sort-by.service";
import {WorkPackageViewGroupByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-group-by.service";
import {WorkPackageViewRelationColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-relation-columns.service";
import {combineLatest} from "rxjs";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";


@Component({
  selector: 'sortHeader',
  templateUrl: './sort-header.directive.html'
})
export class SortHeaderDirective extends UntilDestroyedMixin implements AfterViewInit {

  @Input() headerColumn:any;

  @Input() locale:string;

  @Input() table:WorkPackageTable;

  sortable:boolean;

  directionClass:string;

  public text = {
    toggleHierarchy: this.I18n.t('js.work_packages.hierarchy.show'),
    openMenu: this.I18n.t('js.label_open_menu'),
    sortColumn: 'Sorting column' // TODO
  };

  isHierarchyColumn:boolean;

  columnType:'hierarchy'|'relation'|'sort';

  columnName:string;

  hierarchyIcon:string;

  isHierarchyDisabled:boolean;

  private element:JQuery;

  private currentSortDirection:any;

  constructor(private wpTableHierarchies:WorkPackageViewHierarchiesService,
              private wpTableSortBy:WorkPackageViewSortByService,
              private wpTableGroupBy:WorkPackageViewGroupByService,
              private wpTableRelationColumns:WorkPackageViewRelationColumnsService,
              private elementRef:ElementRef,
              private cdRef:ChangeDetectorRef,
              private I18n:I18nService) {
    super();
  }

  ngAfterViewInit() {
    setTimeout(() => this.initialize());
  }

  private initialize():void {
    this.element = jQuery(this.elementRef.nativeElement);

    combineLatest([
      this.wpTableSortBy.onReadyWithAvailable(),
      this.wpTableSortBy.live$()
    ])
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(() => {
        let latestSortElement = this.wpTableSortBy.current[0];

        if (!latestSortElement || this.headerColumn.$href !== latestSortElement.column.$href) {
          this.currentSortDirection = null;
        } else {
          this.currentSortDirection = latestSortElement.direction;
        }
        this.setActiveColumnClass();

        this.sortable = this.wpTableSortBy.isSortable(this.headerColumn);

        this.directionClass = this.getDirectionClass();

        this.cdRef.detectChanges();
      });

    // Place the hierarchy icon left to the subject column
    this.isHierarchyColumn = this.headerColumn.id === 'subject';

    if (this.headerColumn.id === 'sortHandle') {
      this.columnType = 'sort';
    }
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
      this.wpTableGroupBy
        .live$()
        .pipe(
          this.untilDestroyed()
        )
        .subscribe(() => {
          this.isHierarchyDisabled = this.wpTableGroupBy.isEnabled;
          this.cdRef.detectChanges();
        });

      // Update hierarchy icon when updated elsewhere
      this.wpTableHierarchies
        .live$()
        .pipe(
          this.untilDestroyed()
        )
        .subscribe(() => {
          this.setHierarchyIcon();
          this.cdRef.detectChanges();
        });

      // Set initial icon
      this.setHierarchyIcon();
    }

    this.cdRef.detectChanges();
  }

  public get displayDropdownIcon() {
    return this.table && this.table.configuration.columnMenuEnabled;
  }

  public get displayHierarchyIcon() {
    return this.table && this.table.configuration.hierarchyToggleEnabled;
  }

  toggleHierarchy(evt:JQuery.TriggeredEvent) {
    if (this.wpTableHierarchies.toggleState()) {
      this.wpTableGroupBy.disable();
    }

    this.setHierarchyIcon();

    evt.stopPropagation();
    return false;
  }

  setHierarchyIcon() {
    if (this.wpTableHierarchies.isEnabled) {
      this.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.hide');
      this.hierarchyIcon = 'icon-hierarchy';
    } else {
      this.text.toggleHierarchy = I18n.t('js.work_packages.hierarchy.show');
      this.hierarchyIcon = 'icon-no-hierarchy';
    }
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



