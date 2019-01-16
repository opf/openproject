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
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostListener,
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
import {distinctUntilChanged} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {GlobalSearchInputComponent} from "core-components/global-search/global-search-input.component";

export const globalSearchWorkPackagesSelector = 'global-search-work-packages';

@Component({
  selector: globalSearchWorkPackagesSelector,
  templateUrl: './global-search-work-packages.component.html'
})

export class GlobalSearchWorkPackagesComponent implements OnDestroy {
  @ViewChild('wpTable') wpTable:ElementRef;

  public queryProps:{ [key:string]:any };

  public configuration = {
    actionsColumnEnabled: false,
    columnMenuEnabled: false,
    contextMenuEnabled: false,
    inlineCreateEnabled: false
  };

  public text:{ [key:string]:string } = {
    all_projects: this.I18n.t('js.global_search.all_projects'),
  };

  constructor(readonly FocusHelper:FocusHelperService,
              readonly elementRef:ElementRef,
              readonly renderer:Renderer2,
              readonly I18n:I18nService,
              readonly PathHelperService:PathHelperService,
              readonly halResourceService:HalResourceService,
              readonly dynamicCssService:DynamicCssService,
              readonly globalSearchService:GlobalSearchService,
              readonly cdRef:ChangeDetectorRef,
              readonly currentProjectService:CurrentProjectService) {
  }

  ngOnInit() {
    this.globalSearchService.searchTerm$.subscribe((_searchTerm) => this.setQueryProps());
    this.globalSearchService.projectScope$.subscribe((_projectScope) => this.setQueryProps());
    this.setQueryProps();
  }

  private setQueryProps():void {
    this.queryProps = {
      'columns[]': ['id', 'project', 'type', 'subject', 'updatedAt'],
      filters: JSON.stringify([{ search: {
                              operator: '**',
                              values: [this.globalSearchService.searchTerm] }}]),
      sortBy: JSON.stringify([['updatedAt', 'desc']])
    };
    console.log("queryProps", this.queryProps);
  }

  ngOnDestroy():void {
    // nothing to do
  }
}

DynamicBootstrapper.register({
  selector: globalSearchWorkPackagesSelector, cls: GlobalSearchWorkPackagesComponent
});
