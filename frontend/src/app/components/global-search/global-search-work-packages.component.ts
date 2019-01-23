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
  HostListener, Injector,
  OnDestroy,
  Renderer2,
  ViewChild
} from '@angular/core';
import {ContainHelpers} from 'core-app/modules/common/focus/contain-helpers';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {DynamicCssService} from "core-app/modules/common/dynamic-css/dynamic-css.service";
import {GlobalSearchService} from "core-components/global-search/global-search.service";
import {debounceTime, distinctUntilChanged} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {GlobalSearchInputComponent} from "core-components/global-search/global-search-input.component";
import {Subscription} from "rxjs";
import {WorkPackageTableFilters} from "core-components/wp-fast-table/wp-table-filters";
import {WorkPackageTableFiltersService} from "core-components/wp-fast-table/state/wp-table-filters.service";
import {QueryFiltersComponent} from "core-components/filters/query-filters/query-filters.component";
import {WorkPackageEmbeddedTableComponent} from "core-components/wp-table/embedded/wp-embedded-table.component";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {QueryFormResource} from "core-app/modules/hal/resources/query-form-resource";
import {QueryFormDmService} from "core-app/modules/hal/dm-services/query-form-dm.service";
import {WorkPackageFiltersService} from "core-components/filters/wp-filters/wp-filters.service";

export const globalSearchWorkPackagesSelector = 'global-search-work-packages';

@Component({
  selector: globalSearchWorkPackagesSelector,
  templateUrl: '/app/components/wp-table/embedded/wp-embedded-table.html'
})

export class GlobalSearchWorkPackagesComponent extends WorkPackageEmbeddedTableComponent implements OnDestroy {
  @ViewChild('wpTable') wpTable:WorkPackageEmbeddedTableComponent;

  private searchTermSub:Subscription;
  private projectScopeSub:Subscription;
  private resultsHiddenSub:Subscription;

  public filters:WorkPackageTableFilters;
  public queryProps:{ [key:string]:any };

  constructor(readonly FocusHelper:FocusHelperService,
              readonly elementRef:ElementRef,
              readonly renderer:Renderer2,
              readonly I18n:I18nService,
              readonly halResourceService:HalResourceService,
              readonly globalSearchService:GlobalSearchService,
              readonly cdRef:ChangeDetectorRef,
              injector:Injector,
              private QueryFormDm:QueryFormDmService) {
    super(injector);
  }

  ngOnInit() {
    super.ngOnInit();

    this.configuration.actionsColumnEnabled = false;
    this.configuration.columnMenuEnabled = false;
    this.configuration.contextMenuEnabled = false;
    this.configuration.inlineCreateEnabled = false;
    this.configuration.withFilters = true;
    this.configuration.showFilterButton = true;
    this.configuration.filterButtonText = I18n.t('js.button_advanced_filter')

    this.searchTermSub = this.globalSearchService
      .searchTerm$
      .subscribe((_searchTerm) => this.setQueryProps());

    this.projectScopeSub = this.globalSearchService
      .projectScope$
      .subscribe((_projectScope) => this.setQueryProps());

    this.resultsHiddenSub = this.globalSearchService
      .resultsHidden$
      .subscribe((resultsHidden:boolean) => this.show = !resultsHidden);

    this.setQueryProps();
  }

  protected loadQuery(visible:boolean = true) {
    return super.loadQuery(visible).then((query:QueryResource) => {
      this.loadForm(query);
      return query;
    });
  }

  private loadForm(query:QueryResource):Promise<QueryFormResource> {
    return this.QueryFormDm.load(query).then((form:QueryFormResource) => {
      this.wpStatesInitialization.updateStatesFromForm(query, form);
      return form;
    });
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
      sortBy: JSON.stringify([['updatedAt', 'desc']])
    };

    this.refresh();
  }

  ngOnDestroy():void {
    this.searchTermSub.unsubscribe();
    this.projectScopeSub.unsubscribe();
  }
}

DynamicBootstrapper.register({
  selector: globalSearchWorkPackagesSelector, cls: GlobalSearchWorkPackagesComponent
});
