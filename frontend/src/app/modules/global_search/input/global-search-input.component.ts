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
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostListener,
  OnDestroy,
  OnInit,
  ViewChild,
  ViewEncapsulation
} from '@angular/core';
import {ContainHelpers} from 'core-app/modules/common/focus/contain-helpers';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {GlobalSearchService} from "core-app/modules/global_search/services/global-search.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {DeviceService} from "core-app/modules/common/browser/device.service";
import {NgSelectComponent} from "@ng-select/ng-select";
import {Observable, of} from "rxjs";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {map} from "rxjs/internal/operators";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {DebouncedRequestSwitchmap, errorNotificationHandler} from "core-app/helpers/rxjs/debounced-input-switchmap";

export const globalSearchSelector = 'global-search-input';

interface SearchResultItem {
  id:string;
  subject:string;
  status:string;
  statusId:string;
  $href:string;
}

@Component({
  selector: globalSearchSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './global-search-input.component.html',
  styleUrls: ['./global-search-input.component.sass', "./global-search-input-mobile.component.sass"],
  // Necessary because of ng-select
  encapsulation: ViewEncapsulation.None
})
export class GlobalSearchInputComponent implements OnInit, OnDestroy {
  @ViewChild('btn', { static: true }) btn:ElementRef;
  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  public expanded:boolean = false;
  public suggestions:any[];

  /** Keep a switchmap for search term and loading state */
  public requests = new DebouncedRequestSwitchmap<string, SearchResultItem>(
    (searchTerm:string) => this.autocompleteWorkPackages(searchTerm),
    errorNotificationHandler(this.wpNotification)
  );

  /** Remember the current value */
  public currentValue:string = '';

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
              readonly globalSearchService:GlobalSearchService,
              readonly currentProjectService:CurrentProjectService,
              readonly deviceService:DeviceService,
              readonly cdRef:ChangeDetectorRef,
              readonly wpNotification:WorkPackageNotificationService) {
  }

  ngOnInit() {
    // check searchterm on init, expand / collapse search bar and set correct classes
    this.ngSelectComponent.filterValue = this.currentValue = this.globalSearchService.searchTerm;
    this.expanded = (this.ngSelectComponent.filterValue.length > 0);
    jQuery('#top-menu').toggleClass('-global-search-expanded', this.expanded);


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

  public search($event:any) {
    this.currentValue = this.ngSelectComponent.filterValue;
    this.openCloseMenu($event.term);
  }

  // close menu when input field is empty
  public openCloseMenu(searchedTerm:string) {
    this.ngSelectComponent.isOpen = (searchedTerm.trim().length > 0);
  }

  public onFocus() {
    this.expanded = true;
    jQuery('#top-menu').addClass('-global-search-expanded');
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
    if (!this.requests.hasResults) {
      this.searchInScope(this.currentScope);
    }
  }

  public statusHighlighting(statusId:string) {
    return Highlighting.inlineClass('status', statusId);
  }


  // return all project scope items and all items which contain the search term
  public customSearchFn(term:string, item:any):boolean {
    return item.id === undefined || item.subject.toLowerCase().indexOf(term.toLowerCase()) !== -1;
  }

  private autocompleteWorkPackages(query:string):Observable<SearchResultItem[]> {
    if (!query) {
      return of([]);
    }

    let idOnly:boolean = false;

    if (query.match(/^#\d+$/)) {
      query = query.replace(/^#/, '');
      idOnly = true;
    }

    let href:string = this.PathHelperService.api.v3.wpBySubjectOrId(query, idOnly);

    this.addSuggestions();

    return this.halResourceService
      .get<CollectionResource<WorkPackageResource>>(href)
      .pipe(
        map((collection) => {
          return this.suggestions.concat(collection.elements.map((wp) => {
            return {
              id: wp.id!,
              subject: wp.subject,
              status: wp.status.name,
              statusId: wp.status.idFromLink,
              $href: wp.$href
            };
          }));
        })
      );
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
