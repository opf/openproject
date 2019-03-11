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
  Component,
  ElementRef,
  OnInit,
  OnDestroy,
  ViewChild,
  HostListener,
  ChangeDetectorRef
} from '@angular/core';
import {ContainHelpers} from 'app/modules/common/focus/contain-helpers';
import {I18nService} from 'app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "app/globals/dynamic-bootstrapper";
import {PathHelperService} from "app/modules/common/path-helper/path-helper.service";
import {HalResourceService} from "app/modules/hal/services/hal-resource.service";
import {WorkPackageResource} from "app/modules/hal/resources/work-package-resource";
import {CollectionResource} from "app/modules/hal/resources/collection-resource";
import {DynamicCssService} from "app/modules/common/dynamic-css/dynamic-css.service";
import {GlobalSearchService} from "app/modules/global_search/global-search.service";
import {CurrentProjectService} from "app/components/projects/current-project.service";
import {DeviceService} from "app/modules/common/browser/device.service";
import {NgSelectComponent} from "@ng-select/ng-select";
import {debounceTime, distinctUntilChanged} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {Subject} from "rxjs";

export const globalSearchSelector = 'global-search-input';

@Component({
  selector: globalSearchSelector,
  templateUrl: './global-search-input.component.html'
})

export class GlobalSearchInputComponent implements OnInit, OnDestroy {
  @ViewChild('btn') btn:ElementRef;
  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  public currentValue:string = '';
  public expanded:boolean = false;
  public noResults:boolean = true;
  public results:any[];
  public suggestions:any[];

  public searchTermChanged$:Subject<string> = new Subject<string>();

  private $element:JQuery;
  private isFirstFocus:boolean = true;

  private unregisterGlobalListener:Function | undefined;

  public text:{ [key:string]:string } = {
    all_projects: this.I18n.t('js.global_search.all_projects'),
    current_project: this.I18n.t('js.global_search.current_project'),
    current_project_and_all_descendants: this.I18n.t('js.global_search.current_project_and_all_descendants'),
    search: this.I18n.t('js.global_search.search'),
    search_dots: this.I18n.t('js.global_search.search') + ' ...',
    close_search: this.I18n.t('js.global_search.close_search')
  };

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly PathHelperService:PathHelperService,
              readonly halResourceService:HalResourceService,
              readonly dynamicCssService:DynamicCssService,
              readonly globalSearchService:GlobalSearchService,
              readonly currentProjectService:CurrentProjectService,
              readonly deviceService:DeviceService,
              readonly cdRef:ChangeDetectorRef) {
  }

  private projectScopeTypes = ['all_projects', 'current_project', 'current_project_and_all_descendants'];

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    // check searchterm on init, expand / collapse search bar and set correct classes
    this.ngSelectComponent.filterValue = this.currentValue = this.globalSearchService.searchTerm;
    this.expanded = (this.ngSelectComponent.filterValue.length > 0);
    jQuery('#top-menu').toggleClass('-global-search-expanded', this.expanded);

    this.searchTermChanged$
      .pipe(
        distinctUntilChanged(),
        debounceTime(250),
        untilComponentDestroyed(this)
      )
      .subscribe((_searchTerm:string) => {
        // load result list for searched term
        if (this.currentValue.trim().length > 0) {
          this.getSearchResult(this.currentValue);
        }

        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy() {
    this.unregister();
  }

  // detect if click is outside or inside the element
  @HostListener('click', ['$event'])
  public handleClick(event:JQueryEventObject):void {
    event.stopPropagation();
    event.preventDefault();

    // handle click on search button
    if (ContainHelpers.insideOrSelf(this.btn.nativeElement, event.target)) {
      if (this.deviceService.isMobile) {
        this.toggleMobileSearch();
        // open ng-select menu on default
        jQuery('.ng-input input').focus();
      } else if (this.ngSelectComponent.filterValue.length === 0) {
        this.ngSelectComponent.focus();
      } else {
        this.submitNonEmptySearch();
      }
    }
  }

  // open or close mobile search
  public toggleMobileSearch() {
    this.expanded = !this.expanded;
    jQuery('#top-menu').toggleClass('-global-search-expanded', this.expanded);
  }

  // load selected item
  public onChange($event:any) {
    let selectedOption = $event;
    if (selectedOption.id) {  // item is a work package element
      this.redirectToWp(selectedOption.id);
    } else {                  // item is a 'scope' element
      // update embedded table and title when new search is submitted
      this.globalSearchService.searchTerm = this.currentValue;
      this.searchInScope(selectedOption.projectScope);
    }
  }

  public search($event:string) {
    this.currentValue = this.ngSelectComponent.filterValue;
    this.openCloseMenu($event);
  }

  // close menu when input field is empty
  public openCloseMenu(searchedTerm:string) {
    this.ngSelectComponent.isOpen = (searchedTerm.trim().length > 0);
  }

  public onFocus() {
    this.expanded = true;
    jQuery('#top-menu').addClass('-global-search-expanded');
    // load result list after page reload
    if (this.isFirstFocus && (this.currentValue || '').length > 0) {
      this.isFirstFocus = false;
      this.getSearchResult(this.ngSelectComponent.filterValue);
    }
    this.openCloseMenu(this.currentValue);
  }

  public onFocusOut() {
    if (!this.deviceService.isMobile) {
      this.expanded = (this.ngSelectComponent.filterValue.length > 0);
      this.ngSelectComponent.isOpen = false;
      jQuery('#top-menu').toggleClass('-global-search-expanded', this.expanded);
    }
  }

  public clearSearch() {
    this.currentValue = this.ngSelectComponent.filterValue = '';
    this.openCloseMenu(this.currentValue);
  }

  // If Enter key is pressed before result list is loaded submit search in current scope
  public onEnterBeforeResultsLoaded() {
    if (this.noResults) {
      this.searchInScope(this.currentScope);
    }
  }

  // get work packages result list and append it to suggestions
  private getSearchResult(term:string) {
    this.autocompleteWorkPackages(term).then((values) => {
      this.results = this.suggestions.concat(values.map((wp:any) => {
        return {
          id: wp.id,
          subject: wp.subject,
          status: wp.status.name,
          statusId: wp.status.idFromLink,
          $href: wp.$href
        };
      }));
    });
  }

  // return all project scope items and all items which contain the search term
  public customSearchFn(term:string, item:any):boolean {
    return item.id === undefined || item.subject.toLowerCase().indexOf(term.toLowerCase()) !== -1;
  }

  private autocompleteWorkPackages(query:string):Promise<(any)[]> {
    this.dynamicCssService.requireHighlighting();

    this.$element.find('.ui-autocomplete--loading').show();
    this.noResults = true;

    let idOnly:boolean = false;

    if (query.match(/^#\d+$/)) {
      query = query.replace(/^#/, '');
      idOnly = true;
    }

    let href:string = this.PathHelperService.api.v3.wpBySubjectOrId(query, idOnly);

    this.addSuggestions();

    return this.halResourceService
      .get<CollectionResource<WorkPackageResource>>(href)
      .toPromise()
      .then((collection) => {
        this.hideSpinner();
        return collection.elements;
      }).catch(() => {
        this.hideSpinner();
        return [];
      });
  }

  // set the possible 'search in scope' options for the current project path
  private addSuggestions() {
    this.suggestions = [];
    // add all options when searching within a project
    // otherwise search in 'all projects'
    if (this.currentProjectService.path) {
      this.suggestions.push('current_project_and_all_descendants');
      this.suggestions.push('current_project');
    }
    if (this.globalSearchService.projectScope === 'current_project') {
      this.suggestions.reverse();
    }
    this.suggestions.push('all_projects');

    this.suggestions = this.suggestions.map((suggestion:string) => {
      return { projectScope: suggestion, text: this.text[suggestion] };
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
      case 'current_project': {
        this.globalSearchService.projectScope = 'current_project';
        this.submitNonEmptySearch();
        break;
      }
      case 'current_project_and_all_descendants': {
        this.globalSearchService.projectScope = '';
        this.submitNonEmptySearch();
        break;
      }
    }
  }

  public submitNonEmptySearch(forcePageLoad:boolean = false) {
    this.globalSearchService.searchTerm = this.currentValue;
    if (this.currentValue.length > 0) {
      this.ngSelectComponent.close();
      // Work package results can update without page reload.
      if (!forcePageLoad &&
          this.globalSearchService.isAfterSearch() &&
          this.globalSearchService.currentTab === 'work_packages') {
        window.history
          .replaceState({},
            `${I18n.t('global_search.search')}: ${this.ngSelectComponent.filterValue}`,
            this.globalSearchService.searchPath());

        return;
      }
      this.globalSearchService.submitSearch();
    }
  }

  public blur() {
    this.ngSelectComponent.filterValue = '';
    (<HTMLInputElement> document.activeElement).blur();
  }

  private redirectToWp(id:string) {
    window.location = this.PathHelperService.workPackagePath(id) as unknown as Location;
  }

  private hideSpinner():void {
    this.$element.find('.ui-autocomplete--loading').hide()
    this.noResults = false;
  }

  private get currentScope():string {
    let serviceScope = this.globalSearchService.projectScope;
    return (serviceScope === '') ? 'current_project_and_all_descendants' : serviceScope;
  }

  private unregister() {
    if (this.unregisterGlobalListener) {
      this.unregisterGlobalListener();
      this.unregisterGlobalListener = undefined;
    }
  }
}

DynamicBootstrapper.register({
  selector: globalSearchSelector, cls: GlobalSearchInputComponent
});
