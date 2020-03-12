//-- copyright
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
//++
import {ChangeDetectorRef, Component, ElementRef, Injector, Input, OnDestroy} from '@angular/core';
import {distinctUntilChanged} from 'rxjs/operators';
import {combineLatest} from 'rxjs';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {GlobalSearchService} from "core-app/modules/global_search/services/global-search.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

export const globalSearchTitleSelector = 'global-search-title';

@Component({
  selector: 'global-search-title',
  templateUrl: './global-search-title.component.html'
})
export class GlobalSearchTitleComponent extends UntilDestroyedMixin implements OnDestroy {
  @Input() public searchTerm:string;
  @Input() public project:string;
  @Input() public projectScope:string;
  @Input() public searchTitle:string;

  @InjectField() private currentProjectService:CurrentProjectService;

  public text:{ [key:string]:string } = {
    all_projects: this.I18n.t('js.global_search.title.all_projects'),
    project_and_subprojects: this.I18n.t('js.global_search.title.project_and_subprojects'),
    search_for: this.I18n.t('js.global_search.title.search_for'),
    in: this.I18n.t('js.label_in')
  };

  constructor(readonly elementRef:ElementRef,
              readonly cdRef:ChangeDetectorRef,
              readonly globalSearchService:GlobalSearchService,
              readonly I18n:I18nService,
              readonly injector:Injector) {
    super();
  }

  ngOnInit() {
    // Listen on changes of search input value and project scope
    combineLatest([
      this.globalSearchService.searchTerm$,
      this.globalSearchService.projectScope$
    ])
      .pipe(
        distinctUntilChanged(),
        this.untilDestroyed()
      )
      .subscribe(([newSearchTerm, newProjectScope]) => {
        this.searchTerm = newSearchTerm;
        this.project = this.projectText(newProjectScope);
        this.searchTitle = `${this.text.search_for} ${this.searchTerm} ${this.project === '' ? '' : this.text.in} ${this.project}`;

        this.cdRef.detectChanges();
      });
  }

  private projectText(scope:string):string {
    let currentProjectName = this.currentProjectService.name ? this.currentProjectService.name : '';

    switch (scope) {
      case 'all':
        return this.text.all_projects;
        break;
      case 'current_project':
        return currentProjectName;
        break;
      case '':
        return currentProjectName + ' ' + this.text.project_and_subprojects;
        break;
      default:
        return '';
    }
  }
}
