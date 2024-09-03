//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostListener,
  Input,
  NgZone,
  OnDestroy,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { first, map, switchMap, tap } from 'rxjs/operators';
import { GlobalSearchService } from 'core-app/core/global_search/services/global-search.service';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import {
  Highlighting,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { DeviceService } from 'core-app/core/browser/device.service';
import { insideOrSelf } from 'core-app/shared/directives/focus/contain-helpers';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  OpAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ApiV3Service } from '../../apiv3/api-v3.service';
import {
  ApiV3WorkPackageCachedSubresource,
} from 'core-app/core/apiv3/endpoints/work_packages/api-v3-work-package-cached-subresource';
import { RecentItemsService } from 'core-app/core/recent-items.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

interface SearchResultItem {
  id:string;
  subject:string;
  status:string;
  statusId:string;
  href:string;
  project:string;
  author:HalResource;
}

interface SearchOptionItem {
  projectScope:string;
  text:string;
}

interface SearchResultItems {
  items:SearchResultItem[]|SearchOptionItem[];
  term:string;
}

@Component({
  selector: 'opce-global-search',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './global-search-input.component.html',
  styleUrls: [
    './global-search-input.component.sass',
    './global-search-input-mobile.component.sass',
    './global-search.component.sass',
  ],
  // Necessary because of ng-select
  encapsulation: ViewEncapsulation.None,
})
export class GlobalSearchInputComponent implements AfterViewInit, OnDestroy {
  @Input() public placeholder:string;

  @ViewChild('btn', { static: true }) btn:ElementRef;

  @ViewChild(OpAutocompleterComponent, { static: true }) public ngSelectComponent:OpAutocompleterComponent;

  public expanded = false;

  private _markable = new BehaviorSubject<boolean>(false);

  public markable$ = this._markable.asObservable();

  public hasRecentItems$ = this.recentItemsService.recentItems$.pipe(
    map((items) => (items.length > 0)),
  );

  getAutocompleterData = ():Observable<unknown[]> => this.autocompleteWorkPackages();

  public autocompleterOptions = {
    filters: [],
    resource: 'work_packages',
    searchKey: 'subjectOrId',
    getOptionsFn: this.getAutocompleterData,
  };

  /** Remember the item that best matches the query.
   * That way, it will be highlighted (as we manually mark the selected item) and we can handle enter.
   * */
  public selectedItem:WorkPackageResource|SearchOptionItem|undefined = undefined;

  /** Remember the current value */
  public currentValue = '';

  public isFocusedDirectly = this.globalSearchService.searchTerm.length > 0 && this.selectedItem instanceof HalResource;

  private unregisterGlobalListener:(() => unknown)|undefined;

  public text:{ [key:string]:string } = {
    all_projects: this.I18n.t('js.global_search.all_projects'),
    close_search: this.I18n.t('js.global_search.close_search'),
    current_project_and_all_descendants: this.I18n.t('js.global_search.current_project_and_all_descendants'),
    current_project: this.I18n.t('js.global_search.current_project'),
    recently_viewed: this.I18n.t('js.global_search.recently_viewed'),
  };

  constructor(
    readonly elementRef:ElementRef,
    readonly I18n:I18nService,
    readonly apiV3Service:ApiV3Service,
    readonly pathHelperService:PathHelperService,
    readonly halResourceService:HalResourceService,
    readonly globalSearchService:GlobalSearchService,
    readonly currentProjectService:CurrentProjectService,
    readonly deviceService:DeviceService,
    readonly cdRef:ChangeDetectorRef,
    readonly halNotification:HalResourceNotificationService,
    readonly ngZone:NgZone,
    readonly recentItemsService:RecentItemsService,
  ) {
    populateInputsFromDataset(this);
  }

  ngAfterViewInit():void {
    // check searchterm on init, expand / collapse search bar and set correct classes
    this.searchTerm = this.globalSearchService.searchTerm;
    this.currentValue = '';
    this.toggleTopMenuClass();
  }

  ngOnDestroy():void {
    this.unregister();
  }

  public set searchTerm(searchTerm:string) {
    this.ngSelectComponent.ngSelectInstance.searchTerm = searchTerm;
  }

  public get searchTerm():string {
    return this.ngSelectComponent.ngSelectInstance.searchTerm;
  }

  public set markable(value:boolean) {
    this._markable.next(value);
  }

  public get markable():boolean {
    return this._markable.value;
  }

  // detect if click is outside or inside the element
  @HostListener('click', ['$event'])
  public handleClick(event:JQuery.TriggeredEvent):void {
    event.preventDefault();

    // handle click on search button
    if (insideOrSelf(this.btn.nativeElement as HTMLElement, event.target as HTMLElement)) {
      if (this.deviceService.isMobile) {
        this.toggleMobileSearch();
        // open ng-select menu on default
        jQuery('.ng-input input').focus();
        // only for mobile and not for all devices!
        // See https://github.com/opf/openproject/commit/a2eb0cd6025f2ecaca00f4ed81c4eb8e9399bd86
        event.stopPropagation();
      } else if (this.searchTerm?.length === 0) {
        this.ngSelectComponent.ngSelectInstance.focus();
      } else {
        this.submitNonEmptySearch();
      }
    }
  }

  // open or close mobile search
  public toggleMobileSearch():void {
    this.expanded = !this.expanded;
    this.toggleTopMenuClass();
  }

  public redirectToWp(id:string, event:MouseEvent):boolean {
    event.stopImmediatePropagation();
    if (isClickedWithModifier(event)) {
      return true;
    }

    window.location.href = this.wpPath(id);
    event.preventDefault();
    return false;
  }

  public wpPath(id:string):string {
    return this.pathHelperService.workPackagePath(id);
  }

  public highlighting(property:string, id:string):string {
    return Highlighting.inlineClass(property, id);
  }

  public search(_$event:SearchResultItems):void {
    this.currentValue = this.searchTerm;
  }

  public onFocus():void {
    this.expanded = true;
    this.toggleTopMenuClass();
    this.ngSelectComponent.openSelect();
  }

  public onFocusOut():void {
    if (!this.deviceService.isMobile) {
      this.expanded = (this.searchTerm !== null && this.searchTerm.length > 0);
      this.ngSelectComponent.ngSelectInstance.isOpen = false;
      this.selectedItem = undefined;
      this.toggleTopMenuClass();
    }

    (<HTMLInputElement>document.activeElement).blur();
  }

  public onClose():void {
    this.searchTerm = this.currentValue;
  }

  public clearSearch():void {
    this.currentValue = '';
    this.searchTerm = '';
  }

  // If Enter key is pressed before result list is loaded, wait for the results to come
  // in and then decide what to do. If a direct hit is present, follow that. Otherwise,
  // go to the search in the current scope.
  public onEnterBeforeResultsLoaded():void {
    this.markable$.pipe(
      first((v) => v),
    ).subscribe(() => {
      if (this.selectedItem) {
        this.followSelectedItem();
      } else {
        this.searchInScope(this.currentScope);
      }
    });
  }

  public statusHighlighting(statusId:string):string {
    return Highlighting.inlineClass('status', statusId);
  }

  public followItem(item:WorkPackageResource|SearchOptionItem|undefined):void {
    this.selectedItem = item;
    if (item instanceof HalResource) {
      window.location.href = this.wpPath(item.id as string);
    } else if (item) {
      // update embedded table and title when new search is submitted
      this.globalSearchService.searchTerm = this.currentValue;
      this.searchInScope(item.projectScope);
    }
  }

  public followSelectedItem():void {
    if (this.selectedItem) {
      this.followItem(this.selectedItem);
    }
  }

  // return all project scope items and all items which contain the search term
  public customSearchFn(term:string, item:SearchResultItem):boolean {
    return item.id === undefined || item.subject.toLowerCase().indexOf(term.toLowerCase()) !== -1;
  }

  private autocompleteWorkPackages():Observable<(WorkPackageResource|SearchOptionItem)[]> {
    const query = this.searchTerm;
    if (query === null || query.match(/^\s+$/)) {
      return of([]);
    }

    if (!query.length) {
      return this.recentItemsService.recentItems$.pipe(
        switchMap((wpIds) => {
          // It is needed, because otherwise we get infinite spin running
          // in the searchbar with no recent workpackages IDs inside localStorage
          if (wpIds.length === 0) {
            return of([]);
          }

          void this.apiV3Service.work_packages.requireAll(wpIds);
          return this.apiV3Service.work_packages.cache.observeSome(wpIds);
        }),
      );
    }

    // Reset the currently selected item.
    // We do not follow the typical goal of an autocompleter of "setting a value" here.
    this.selectedItem = undefined;
    // Hide highlighting of ng-option
    this.markable = false;

    const hashFreeQuery = this.queryWithoutHash(query);

    return this
      .fetchSearchResults(hashFreeQuery, hashFreeQuery !== query)
      .get()
      .pipe(
        map((collection) => this.searchResultsToOptions(collection.elements, hashFreeQuery)),
        tap(() => {
          this.setMarkedOption();
        }),
      );
  }

  // Remove ID marker # when searching for #<number>
  private queryWithoutHash(query:string):string {
    if (/^#(\d+)/.exec(query)) {
      return query.substr(1);
    }
    return query;
  }

  private fetchSearchResults(query:string, idOnly:boolean):ApiV3WorkPackageCachedSubresource {
    return this
      .apiV3Service
      .work_packages
      .filterByTypeaheadOrId(query, idOnly);
  }

  private searchResultsToOptions(results:WorkPackageResource[], query:string) {
    const searchOptions = this.detailedSearchOptions();
    // If we have a direct hit, we choose it to be the selected element.
    this.selectedItem = results.find((wp) => wp.id?.toString() === query) || searchOptions[0];

    return [
      ...searchOptions,
      ...results,
    ];
  }

  // set the possible 'search in scope' options for the current project path
  private detailedSearchOptions():{ projectScope:string; text:string }[] {
    const searchOptions = [];
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

    return searchOptions.map((suggestion:string) => ({ projectScope: suggestion, text: this.text[suggestion] }));
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
  private setMarkedOption():void {
    this.markable = true;
    this.ngSelectComponent.ngSelectInstance.itemsList.markItem(this.ngSelectComponent.ngSelectInstance.itemsList.selectedItems[0]);

    this.cdRef.detectChanges();
  }

  private searchInScope(scope:string):void {
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
      default: // Do nothing
        break;
    }
  }

  public submitNonEmptySearch(forcePageLoad = false):void {
    this.globalSearchService.searchTerm = this.currentValue;
    if (this.currentValue.length > 0) {
      this.ngSelectComponent.ngSelectInstance.close();
      // Work package results can update without page reload.
      if (!forcePageLoad
        && this.globalSearchService.isAfterSearch()
        && this.globalSearchService.currentTab === 'work_packages') {
        window.history
          .replaceState(
            {},
            `${I18n.t('global_search.search')}: ${this.searchTerm}`,
            this.globalSearchService.searchPath(),
          );

        return;
      }
      this.globalSearchService.submitSearch();
    }
  }

  private get currentScope():string {
    const serviceScope = this.globalSearchService.projectScope;
    return (serviceScope === '') ? 'current_project_and_all_descendants' : serviceScope;
  }

  private unregister():void {
    if (this.unregisterGlobalListener) {
      this.unregisterGlobalListener();
      this.unregisterGlobalListener = undefined;
    }
  }

  private toggleTopMenuClass():void {
    const el = document.getElementsByClassName('op-app-header')[0] as HTMLElement;
    el.classList.toggle('op-app-header_search-open', this.expanded);
    el.dataset.qaSearchOpen = '1';
  }
}
