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

import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  ElementRef,
  OnDestroy,
  OnInit,
  Renderer2,
  ViewChild
} from '@angular/core';
import {FocusHelperService} from 'app/modules/common/focus/focus-helper';
import {I18nService} from 'app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "app/globals/dynamic-bootstrapper";
import {HalResourceService} from "app/modules/hal/services/hal-resource.service";
import {GlobalSearchService} from "app/modules/global_search/global-search.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageTableFilters} from "app/components/wp-fast-table/wp-table-filters";
import {QueryResource} from "app/modules/hal/resources/query-resource";
import {WorkPackageFiltersService} from "app/components/filters/wp-filters/wp-filters.service";
import {UrlParamsHelperService} from "app/components/wp-query/url-params-helper";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import {WorkPackageIsolatedQuerySpaceDirective} from "core-app/modules/work_packages/query-space/wp-isolated-query-space.directive";
import {cloneHalResource} from "core-app/modules/hal/helpers/hal-resource-builder";

export const globalSearchWorkPackagesSelector = 'global-search-work-packages';

@Component({
  selector: globalSearchWorkPackagesSelector,
  template: `
    <ng-container wp-isolated-query-space>
     <wp-embedded-table *ngIf="!resultsHidden"
                        [queryProps]="queryProps"
                        (onFiltersChanged)="onFiltersChanged($event)"
                        [configuration]="tableConfiguration">
      </wp-embedded-table>
    </ng-container>
  `
})

export class GlobalSearchWorkPackagesComponent implements OnInit, OnDestroy, AfterViewInit {
  @ViewChild(WorkPackageIsolatedQuerySpaceDirective) isolatedQueryDirective:WorkPackageIsolatedQuerySpaceDirective;

  public filters:WorkPackageTableFilters;
  public queryProps:{ [key:string]:any };
  public resultsHidden = false;

  public tableConfiguration:WorkPackageTableConfigurationObject = {
    actionsColumnEnabled: false,
    columnMenuEnabled: true,
    contextMenuEnabled: false,
    inlineCreateEnabled: false,
    withFilters: true,
    showFilterButton: true,
    filterButtonText: this.I18n.t('js.button_advanced_filter')
  };

  constructor(readonly FocusHelper:FocusHelperService,
              readonly elementRef:ElementRef,
              readonly renderer:Renderer2,
              readonly I18n:I18nService,
              readonly halResourceService:HalResourceService,
              readonly globalSearchService:GlobalSearchService,
              readonly cdRef:ChangeDetectorRef,
              private UrlParamsHelper:UrlParamsHelperService) {
  }

  ngAfterViewInit() {
    this.globalSearchService
      .searchTerm$
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((_searchTerm) => {
        this.isolatedQueryDirective.runInSpace((injector) => {
          injector.get(WorkPackageFiltersService).visible = false;
        });
        this.setQueryProps();
      });

    this.globalSearchService
      .projectScope$
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((_projectScope) => this.setQueryProps());

    this.globalSearchService
      .resultsHidden$
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((resultsHidden:boolean) => this.resultsHidden = resultsHidden);
  }

  ngOnInit():void {
    this.setQueryProps();
  }

  ngOnDestroy():void {
    // Nothing to do
  }

  public onFiltersChanged(filters:WorkPackageTableFilters) {
    if (filters.isComplete()) {
      const query = this.isolatedQueryDirective.runInSpace((i, querySpace) => cloneHalResource(querySpace.query.value!)) as QueryResource;
      query.filters = filters.current;
      this.queryProps = this.UrlParamsHelper.buildV3GetQueryFromQueryResource(query);
    }
  }

  /**
   * Ensure change detection compatible update of table configuration object
   * @param update
   */
  private setConfiguration(update:WorkPackageTableConfigurationObject) {
    this.tableConfiguration = {
      ...this.tableConfiguration,
      ...update
    };
  }

  private setQueryProps():void {
    let filters:any[] = [];

    if (this.globalSearchService.searchTerm.length > 0) {
      filters.push({ search: {
          operator: '**',
          values: [this.globalSearchService.searchTerm] }});
    }

    if (this.globalSearchService.projectScope === 'current_project') {
      filters.push({ subprojectId: {
          operator: '!*',
          values: [] }});
    }

    if (this.globalSearchService.projectScope === '') {
      filters.push({ subprojectId: {
          operator: '*',
          values: [] }});
    }

    this.queryProps = {
      'columns[]': ['id', 'project', 'type', 'subject', 'updatedAt'],
      filters: JSON.stringify(filters),
      sortBy: JSON.stringify([['updatedAt', 'desc']]),
      showHierarchies: false
    };
  }
}

DynamicBootstrapper.register({
  selector: globalSearchWorkPackagesSelector, cls: GlobalSearchWorkPackagesComponent
});
