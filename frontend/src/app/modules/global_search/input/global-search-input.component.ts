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
import {map, tap, take, filter} from "rxjs/internal/operators";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {DebouncedRequestSwitchmap, errorNotificationHandler} from "core-app/helpers/rxjs/debounced-input-switchmap";
import {LinkHandling} from "core-app/modules/common/link-handling/link-handling";

export const globalSearchSelector = 'global-search-input';

interface SearchResultItem {
  id:string;
  subject:string;
  status:string;
  statusId:string;
  $href:string;
}

interface SearchOptionItem {
  projectScope:string;
  text:string;
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
  public markable = false;

  /** Keep a switchmap for search term and loading state */
  public requests = new DebouncedRequestSwitchmap<string, SearchResultItem|SearchOptionItem>(
    (searchTerm:string) => this.autocompleteWorkPackages(searchTerm).pipe(
      tap(() => {
        setTimeout(() => this.setMarkedOption(), 50);
      })
    ),
    errorNotificationHandler(this.halNotification)
  );

  /** Remember the current value */
  public currentValue:string = '';

  /** Remember the item that best matches the query.
   * That way, it will be highlighted (as we manually mark the selected item) and we can handle enter.
   * */
  public selectedItem:SearchResultItem|SearchOptionItem|null;

  private unregisterGlobalListener:Function|undefined;

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
              readonly halNotification:HalResourceNotificationService) {
  }

  ngOnInit() {
    // check searchterm on init, expand / collapse search bar and set correct classes
    this.ngSelectComponent.searchTerm = this.currentValue = this.globalSearchService.searchTerm;
    this.expanded = (this.ngSelectComponent.searchTerm.length > 0);
    this.toggleTopMenuClass();
  }

  ngOnDestroy() {
    this.unregister();
  }

  // detect if click is outside or inside the element
  @HostListener('click', ['$event'])
  public handleClick(event:JQuery.TriggeredEvent):void {
    event.stopPropagation();
    event.preventDefault();

    // handle click on search button
    if (ContainHelpers.insideOrSelf(this.btn.nativeElement, event.target)) {
      if (this.deviceService.isMobile) {
        this.toggleMobileSearch();
        // open ng-select menu on default
        jQuery('.ng-input input').focus();
      } else if (this.ngSelectComponent.searchTerm.length === 0) {
        this.ngSelectComponent.focus();
      } else {
        this.submitNonEmptySearch();
      }
    }
  }

  // open or close mobile search
  public toggleMobileSearch() {
    this.expanded = !this.expanded;
    this.toggleTopMenuClass();
  }

  public redirectToWp(id:string, event:JQuery.TriggeredEvent) {
    event.stopImmediatePropagation();
    if (LinkHandling.isClickedWithModifier(event)) {
      return true;
    }

    window.location.href = this.wpPath(id);
    event.preventDefault();
    return false;
  }

  public wpPath(id:string) {
    return this.PathHelperService.workPackagePath(id);
  }

  public search($event:any) {
    this.currentValue = this.ngSelectComponent.searchTerm;
    this.openCloseMenu($event.term);
  }

  // close menu when input field is empty
  public openCloseMenu(searchedTerm:string) {
    this.ngSelectComponent.isOpen = (searchedTerm.trim().length > 0);
  }

  public onFocus() {
    this.expanded = true;
    this.toggleTopMenuClass();
    this.openCloseMenu(this.currentValue);
  }

  public onFocusOut() {
    if (!this.deviceService.isMobile) {
      this.expanded = (this.ngSelectComponent.searchTerm.length > 0);
      this.ngSelectComponent.isOpen = false;
      this.toggleTopMenuClass();
    }
  }

  public clearSearch() {
    this.currentValue = this.ngSelectComponent.searchTerm = '';
    this.openCloseMenu(this.currentValue);
  }

  // If Enter key is pressed before result list is loaded, wait for the results to come
  // in and then decide what to do. If a direct hit is present, follow that. Otherwise,
  // go to the search in the current scope.
  public onEnterBeforeResultsLoaded() {
    this.requests.loading$.pipe(
        filter(value => value === false),
        take(1)
      )
      .subscribe(() => {
        if (this.selectedItem) {
          this.followSelectedItem();
        } else {
          this.searchInScope(this.currentScope);
        }
      });
  }

  public statusHighlighting(statusId:string) {
    return Highlighting.inlineClass('status', statusId);
  }

  private get isDirectHit() {
    return this.selectedItem && this.selectedItem.hasOwnProperty('id');
  }

  public followItem(item:SearchResultItem|SearchOptionItem) {
    if (item.hasOwnProperty('id')) {
      window.location.href = this.wpPath((item as SearchResultItem).id);
    } else {
      // update embedded table and title when new search is submitted
      this.globalSearchService.searchTerm = this.currentValue;
      this.searchInScope((item as SearchOptionItem).projectScope);
    }
  }

  public followSelectedItem() {
    if (this.selectedItem) {
      this.followItem(this.selectedItem);
    }
  }

  // return all project scope items and all items which contain the search term
  public customSearchFn(term:string, item:any):boolean {
    return item.id === undefined || item.subject.toLowerCase().indexOf(term.toLowerCase()) !== -1;
  }

  private autocompleteWorkPackages(query:string):Observable<(SearchResultItem|SearchOptionItem)[]> {
    if (!query) {
      return of([]);
    }

    // Reset the currently selected item.
    // We do not follow the typical goal of an autocompleter of "setting a value" here.
    this.selectedItem = null;
    // Hide highlighting of ng-option
    this.markable = false;


    let hashFreeQuery = this.queryWithoutHash(query);

    return this.fetchSearchResults(hashFreeQuery, hashFreeQuery !== query)
      .pipe(
        map((collection) => {
          return this.searchResultsToOptions(collection.elements, hashFreeQuery);
        })
      );
  }

  // Remove ID marker # when searching for #<number>
  private queryWithoutHash(query:string) {
    if (query.match(/^#(\d+)/)) {
      return query.substr(1);
    } else {
      return query;
    }
  }

  private fetchSearchResults(query:string, idOnly:boolean) {
    let href:string = this.PathHelperService.api.v3.wpBySubjectOrId(query, idOnly);

    return this.halResourceService
      .get<CollectionResource<WorkPackageResource>>(href);

  }

  private searchResultsToOptions(results:WorkPackageResource[], query:string) {
    let searchItems = results.map((wp) => {
      let item =  {
        id: wp.id!,
        subject: wp.subject,
        status: wp.status.name,
        statusId: wp.status.idFromLink,
        $href: wp.$href
      } as SearchResultItem;

      // If we have a direct hit, we choose it to be the selected element.
      if (query === wp.id!.toString()) {
        this.selectedItem = item;
      }

      return item;
    });

    let searchOptions = this.detailedSearchOptions();

    if (!this.selectedItem) {
      this.selectedItem = searchOptions[0];
    }

    return (searchOptions as (SearchResultItem|SearchOptionItem)[]).concat(searchItems);
  }

  // set the possible 'search in scope' options for the current project path
  private detailedSearchOptions() {
    let searchOptions = [];
    // add all options when searching within a project
    // otherwise search in 'all projects'
    if (this.currentProjectService.path) {
      searchOptions.push('current_project_and_all_descendants');
      searchOptions.push('current_project');
    }
    if (this.globalSearchService.projectScope === 'current_project') {
      searchOptions.reverse();
    }
    searchOptions.push('all_projects');

    return searchOptions.map((suggestion:string) => {
      return { projectScope: suggestion, text: this.text[suggestion] };
    });
  }

  /*
   * Set the marked ng-option within ng-select and apply the class to highlight marked options.
   *
   * ng-select differentiates between the selected and the marked option. The selected optinon is the option
   * that is binded via ng-model. The marked option is the one that the user is currently selecting (via mouse or keyboard up/down).
   * When hitting enter, the marked option is taken to be the new selected option. Ng-select will retain the index of the marked
   * option between individual searches. The selected option has no influence on the marked option. This is problematic
   * in our use case as the user might have:
   *   * the mouse hovering (deliberately or not) over the search options which will mark that option.
   *   * marked an option for a previous search but might then have decided to add/remove additional characters to the search.
   *
   * In both cases, whenever the user presses enter then, ng-select assigns the marked option to the ng-model.
   *
   * Our goal however is to either:
   *  * mark the direct hit (id matches) if it available
   *  * mark the first item if there is no direct hit
   *
   * And we need to update the marked option after every search.
   *
   * There is no way of doing this via the interface provided in the template. There is only [markFirst] and it neither allows us
   * to mark a direct hit, nor does it reset after a search. We handle this then by selecting the desired element once the
   * search results are back. We then set the marked option to be the selected option.
   *
   * In order to avoid flickering, a -markable modifyer class is unset/set before/after searching. This will unset the background until we
   * have marked the element we wish to.
   */
  private setMarkedOption() {
    this.markable = true;
    this.ngSelectComponent.itemsList.markItem(this.ngSelectComponent.itemsList.selectedItems[0]);

    this.cdRef.detectChanges();
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
            `${I18n.t('global_search.search')}: ${this.ngSelectComponent.searchTerm}`,
            this.globalSearchService.searchPath());

        return;
      }
      this.globalSearchService.submitSearch();
    }
  }

  public blur() {
    this.ngSelectComponent.searchTerm = '';
    (<HTMLInputElement>document.activeElement).blur();
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

  private toggleTopMenuClass() {
    jQuery('#top-menu').toggleClass('-global-search-expanded', this.expanded);
  }
}


