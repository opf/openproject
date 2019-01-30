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
  ViewChild
} from '@angular/core';
import {ContainHelpers} from 'app/modules/common/focus/contain-helpers';
import {FocusHelperService} from 'app/modules/common/focus/focus-helper';
import {I18nService} from 'app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "app/globals/dynamic-bootstrapper";
import {PathHelperService} from "app/modules/common/path-helper/path-helper.service";
import {HalResourceService} from "app/modules/hal/services/hal-resource.service";
import {WorkPackageResource} from "app/modules/hal/resources/work-package-resource";
import {CollectionResource} from "app/modules/hal/resources/collection-resource";
import {DynamicCssService} from "app/modules/common/dynamic-css/dynamic-css.service";
import {GlobalSearchService} from "app/modules/global_search/global-search.service";
import {debounceTime, distinctUntilChanged} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {CurrentProjectService} from "app/components/projects/current-project.service";
import {Subject, Subscription} from "rxjs";
import {NgSelectComponent} from "@ng-select/ng-select";

export const globalSearchSelector = 'global-search-input';

@Component({
  selector: globalSearchSelector,
  templateUrl: './global-search-input.component.html'
})

export class GlobalSearchInputComponent implements OnDestroy {
  @ViewChild('btn') btn:ElementRef;
  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  public focused:boolean = false;
  public noResults = false;
  public searchTerm:string = '';
  public expanded:boolean = false;
  public results:any[];
  public suggestions:any[];

  private searchTermChanged:Subject<string> = new Subject<string>();

  private $element:JQuery;
  private input:HTMLElement;

  private unregisterGlobalListener:Function | undefined;

  public text:{ [key:string]:string } = {
    all_projects: this.I18n.t('js.global_search.all_projects'),
    this_project: this.I18n.t('js.global_search.this_project'),
    this_project_and_all_descendants: this.I18n.t('js.global_search.this_project_and_all_descendants'),
    search: this.I18n.t('js.global_search.search') + ' ...'
  };

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly PathHelperService:PathHelperService,
              readonly halResourceService:HalResourceService,
              readonly dynamicCssService:DynamicCssService,
              readonly globalSearchService:GlobalSearchService,
              readonly cdRef:ChangeDetectorRef,
              readonly currentProjectService:CurrentProjectService) {
  }

  private projectScopeTypes = ['all_projects', 'this_project', 'this_project_and_all_descendants'];

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
    this.input = this.ngSelectComponent.element;

    this.searchTermChanged
      .pipe(
        distinctUntilChanged(),
        debounceTime(250),
        untilComponentDestroyed(this)
      )
      .subscribe((searchTerm:string) => {
        this.searchTerm = searchTerm;
        this.cdRef.detectChanges();
      });

    this.globalSearchService.searchTerm$
      .pipe(
        distinctUntilChanged(),
        untilComponentDestroyed(this)
      )
      .subscribe((searchTerm:string) => {
        this.searchTerm = searchTerm;
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy():void {
    this.unregister();
  }

  // detect if click is outside or inside the element
  @HostListener('click', ['$event'])
  public handleClick(event:JQueryEventObject):void {
    event.stopPropagation();
    event.preventDefault();

    // TODO: make button load the right query
    if (ContainHelpers.insideOrSelf(this.btn.nativeElement, event.target)) {
      this.submitNonEmptySearch();
    }
    // handle clicks for searching in a specific scope
    let scopeElements = jQuery('.ng-dropdown-header')[0];
    if (scopeElements && ContainHelpers.insideOrSelf(scopeElements, event.target)) {
      let projectScope = jQuery(event.target).parent().find('.search-autocomplete--project-scope').attr("title");
      if (projectScope) {
        this.searchInScope(projectScope);
      }
    }
  }

  // load selected work package
  public onChange($event:any) {
    let selectedOption = $event;
    this.redirectToWp(selectedOption.id);
  }

  // load work packages result list for searched term
  public handleUserInput($event:any) {
    this.searchTerm = $event;

    (this.searchTerm === '') ? this.closeMenu() : this.ngSelectComponent.isOpen = true;

    if (this.searchTerm !== null && this.searchTerm !== '') {
      this.globalSearchService.searchTerm = this.searchTerm;
      this.getSearchResult(this.searchTerm);
    }
  }

  public closeMenu() {
    this.ngSelectComponent.isOpen = false;
  }

  public onFocus() {
    this.expanded = true;
  }

  public onFocusOut() {
    this.expanded = false;
    this.ngSelectComponent.filterValue = this.searchTerm;
    this.closeMenu();
  }

  private getSearchResult(term:string) {
    this.autocompleteWorkPackages(term).then((values) => {
      this.results = values.map((wp:any) => {
        return { id: wp.id, subject: wp.subject, status: wp.status.name, statusId: wp.status.idFromLink, $href: wp.$href };
      });
    });
  }

  private autocompleteWorkPackages(query:string):Promise<(any)[]> {
    this.dynamicCssService.requireHighlighting();

    this.$element.find('.ui-autocomplete--loading').show();
    let idOnly:boolean = false;

    if (query.match(/^#\d+$/)) {
      query = query.replace(/^#/, '');
      idOnly = true;
    }

    let href:string = this.PathHelperService.api.v3.wpBySubjectOrId(query, idOnly);

    this.suggestions = [];
    if (this.currentProjectService.path) {
      this.suggestions.push('this_project_and_all_descendants');
      this.suggestions.push('this_project');
    }
    this.suggestions.push('all_projects');
    this.suggestions = this.suggestions.map((suggestion:string) => {
      return { projectScope: suggestion, text: this.text[suggestion] }
    });

    return this.halResourceService
      .get<CollectionResource<WorkPackageResource>>(href)
      .toPromise()
      .then((collection) => {
        this.noResults = collection.count === 0;
        this.hideSpinner();
        return collection.elements;
      }).catch(() => {
        this.hideSpinner();
        return this.suggestions;
      });
  }

  private searchInScope(scope:string) {
    switch (scope) {
      case 'all_projects': {
        let forcePageLoad = false;
        if (this.globalSearchService.projectScope !== 'all') {
          forcePageLoad = true;
          this.globalSearchService.resultsHidden = true;
        }
        this.globalSearchService.projectScope = 'all';
        this.submitNonEmptySearch(forcePageLoad);
        break;
      }
      case 'this_project': {
        this.globalSearchService.projectScope = 'current_project';
        this.submitNonEmptySearch();
        break;
      }
      case 'this_project_and_all_descendants': {
        this.globalSearchService.projectScope = '';
        this.submitNonEmptySearch();
        break;
      }
      default: {
        // do nothing
      }
    }
  }

  public submitNonEmptySearch(forcePageLoad:boolean = false) {
    this.globalSearchService.searchTerm = this.searchValue;
    if (this.searchValue !== '') {
      // Work package results can update without page reload.
      if (!forcePageLoad &&
          this.globalSearchService.isAfterSearch() &&
          this.globalSearchService.currentTab === 'work_packages') {
        window.history
          .replaceState({},
            `${I18n.t('global_search.search')}: ${this.searchValue}`,
            this.globalSearchService.searchPath());

        return;
      }
      this.globalSearchService.submitSearch();
    }
  }

  private redirectToWp(id:string) {
    window.location = this.PathHelperService.workPackagePath(id) as unknown as Location;
  }

  private hideSpinner():void {
    this.$element.find('.ui-autocomplete--loading').hide();
  }

  private unregister() {
    if (this.unregisterGlobalListener) {
      this.unregisterGlobalListener();
      this.unregisterGlobalListener = undefined;
    }
  }

  private get searchValue() {
    return this.searchTerm ? this.searchTerm : '';
  }
}

DynamicBootstrapper.register({
  selector: globalSearchSelector, cls: GlobalSearchInputComponent
});
