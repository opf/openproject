//-- copyright
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
//++
import {
  ChangeDetectorRef,
  Component,
  Input,
  ElementRef,
  OnDestroy
} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {distinctUntilChanged} from 'rxjs/operators';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {combineLatest} from 'rxjs';
import {GlobalSearchService} from "core-components/global-search/global-search.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {Injector} from "@angular/core";
// import {GlobalSearchInputComponent} from "core-components/global-search/global-search-input.component";

export const globalSearchTitleSelector = 'global-search-title';

@Component({
  selector: 'global-search-title',
  templateUrl: './global-search-title.component.html'
})
export class GlobalSearchTitleComponent implements OnDestroy {
  @Input() public searchTerm:string;
  @Input() public project:string;
  @Input() public projectScope:string;

  private currentProjectService:CurrentProjectService = this.injector.get(CurrentProjectService);

  constructor(readonly elementRef:ElementRef,
              readonly cdRef:ChangeDetectorRef,
              readonly globalSearchService:GlobalSearchService,
              protected injector:Injector) {
  }

  ngOnInit() {
    // Listen on changes of search input value and project scope
    combineLatest(
        this.globalSearchService.searchTerm$,
        this.globalSearchService.projectScope$
    )
    .pipe(
      distinctUntilChanged(),
      untilComponentDestroyed(this)
    )
    .subscribe(([newSearchTerm, newProjectScope]) => {
      this.searchTerm = newSearchTerm;
      this.projectScope = newProjectScope;
      this.project = this.projectText(newProjectScope);

      this.cdRef.detectChanges();
    });
  }

  ngOnDestroy() {
    // Nothing to do
  }

  private projectText(scope:string):string {
    let currentProjectName = this.currentProjectService.name ? this.currentProjectService.name : '';

    if(scope === 'all') {
      return 'all projects';
    } else {
      return currentProjectName;
    }
  }
}


DynamicBootstrapper.register({
  selector: globalSearchTitleSelector, cls: GlobalSearchTitleComponent
});
