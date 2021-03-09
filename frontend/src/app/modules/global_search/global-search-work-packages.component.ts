//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { AfterViewInit, ChangeDetectorRef, Component, ElementRef, OnDestroy, OnInit, Renderer2 } from '@angular/core';
import { FocusHelperService } from 'app/modules/common/focus/focus-helper';
import { I18nService } from 'app/modules/common/i18n/i18n.service';
import { HalResourceService } from "app/modules/hal/services/hal-resource.service";
import { GlobalSearchService } from "core-app/modules/global_search/services/global-search.service";
import { WorkPackageFiltersService } from "app/components/filters/wp-filters/wp-filters.service";
import { UrlParamsHelperService } from "app/components/wp-query/url-params-helper";
import { WorkPackageTableConfigurationObject } from "core-components/wp-table/wp-table-configuration";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { WorkPackageViewFiltersService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import { debounceTime, distinctUntilChanged, skip } from "rxjs/operators";
import { combineLatest } from "rxjs";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";

export const globalSearchWorkPackagesSelector = 'global-search-work-packages';

@Component({
  selector: globalSearchWorkPackagesSelector,
  template: `
    <wp-embedded-table *ngIf="!resultsHidden"
                       [queryProps]="queryProps"
                       [configuration]="tableConfiguration">
    </wp-embedded-table>
  `
})

export class GlobalSearchWorkPackagesComponent extends UntilDestroyedMixin implements OnInit, OnDestroy, AfterViewInit {
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
              readonly wpTableFilters:WorkPackageViewFiltersService,
              readonly querySpace:IsolatedQuerySpace,
              readonly wpFilters:WorkPackageFiltersService,
              readonly cdRef:ChangeDetectorRef,
              private UrlParamsHelper:UrlParamsHelperService) {
    super();
  }

  ngAfterViewInit() {
    combineLatest([
      this.globalSearchService.searchTerm$,
      this.globalSearchService.projectScope$
    ])
      .pipe(
        skip(1),
        distinctUntilChanged(),
        debounceTime(10),
        this.untilDestroyed()
      )
      .subscribe(([newSearchTerm, newProjectScope]) => {
        this.wpFilters.visible = false;
        this.setQueryProps();
      });

    this.globalSearchService
      .resultsHidden$
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((resultsHidden:boolean) => this.resultsHidden = resultsHidden);
  }

  ngOnInit():void {
    this.setQueryProps();
  }

  private setQueryProps():void {
    const filters:any[] = [];
    let columns = ['id', 'project', 'subject', 'type', 'status', 'updatedAt'];

    if (this.globalSearchService.searchTerm.length > 0) {
      filters.push({
        search: {
          operator: '**',
          values: [this.globalSearchService.searchTerm]
        }
      });
    }

    if (this.globalSearchService.projectScope === 'current_project') {
      filters.push({
        subprojectId: {
          operator: '!*',
          values: []
        }
      });
      columns = ['id', 'subject', 'type', 'status', 'updatedAt'];
    }

    if (this.globalSearchService.projectScope === '') {
      filters.push({
        subprojectId: {
          operator: '*',
          values: []
        }
      });
    }

    this.queryProps = {
      'columns[]': columns,
      filters: JSON.stringify(filters),
      sortBy: JSON.stringify([['updatedAt', 'desc']]),
      showHierarchies: false
    };
  }
}

