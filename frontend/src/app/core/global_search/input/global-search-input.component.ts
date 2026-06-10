
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, HostListener, Input, OnDestroy, ViewChild, ViewEncapsulation, inject } from '@angular/core';
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
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { announce } from '@primer/live-region-element';
import { NgOption } from '@ng-select/ng-select';

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
  standalone: false,
})
export class GlobalSearchInputComponent implements AfterViewInit, OnDestroy {
  readonly elementRef = inject(ElementRef);
  readonly I18n = inject(I18nService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly pathHelperService = inject(PathHelperService);
  readonly halResourceService = inject(HalResourceService);
  readonly globalSearchService = inject(GlobalSearchService);
  readonly currentProjectService = inject(CurrentProjectService);
  readonly deviceService = inject(DeviceService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly halNotification = inject(HalResourceNotificationService);
  readonly recentItemsService = inject(RecentItemsService);

  @Input() public placeholder:string;

  @ViewChild('btn', { static: true }) btn:ElementRef;

  @ViewChild(OpAutocompleterComponent, { static: true }) public ngSelectComponent:OpAutocompleterComponent;

  public expanded = false;

  private _searchTermInitialized = false;

  // Computed placeholder that changes based on expanded state
  public get effectivePlaceholder():string {
    return this.expanded
      ? this.I18n.t('js.global_search.search_placeholder_expanded')
      : this.placeholder;
  }

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

  public isFocusedDirectly = !!this.currentQuery && this.selectedItem instanceof HalResource;

  public liveMessage = '';

  private unregisterGlobalListener:(() => unknown)|undefined;

  public text:Record<string, string> = {
    all_projects: this.I18n.t('js.global_search.all_projects'),
    close_search: this.I18n.t('js.global_search.close_search'),
    current_project_and_all_descendants: this.I18n.t('js.global_search.current_project_and_all_descendants'),
    current_project: this.I18n.t('js.global_search.current_project'),
    recently_viewed: this.I18n.t('js.global_search.recently_viewed'),
    search: this.I18n.t('js.autocompleter.search'),
  };

  constructor() {
    populateInputsFromDataset(this);
  }

  ngAfterViewInit():void {
    this.currentValue = '';
    this.toggleTopMenuClass();
  }

  ngOnDestroy():void {
    this.unregister();
  }

  public set searchTerm(searchTerm:string) {
    this.ngSelectComponent.ngSelectInstance.filter(searchTerm);
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
  public handleClick(event:MouseEvent):void {
    event.preventDefault();

    // handle click on search button
    if (insideOrSelf(this.btn.nativeElement as HTMLElement, event.target as HTMLElement)) {
      if (this.deviceService.isTablet) {
        this.toggleMobileSearch();
        // open ng-select menu on default
        document.querySelector<HTMLInputElement>('.ng-input input')?.focus();
        // only for mobile and not for all devices!
        // See https://github.com/opf/openproject/commit/a2eb0cd6025f2ecaca00f4ed81c4eb8e9399bd86
        event.stopPropagation();
      } else if (this.searchTerm?.length === 0) {
        this.ngSelectComponent.ngSelectInstance.focus();
      } else {
        this.submitNonEmptySearch('');
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
    if (!this._searchTermInitialized) {
      this._searchTermInitialized = true;
      this.searchTerm = this.currentQuery ?? '';
      this.currentValue = this.searchTerm;
    }
    this.expanded = true;
    this.toggleTopMenuClass();
    this.ngSelectComponent.openSelect();
  }

  public onFocusOut():void {
    if (!this.deviceService.isMobile) {
      this.expanded = (this.searchTerm !== null && this.searchTerm.length > 0);
      this.ngSelectComponent.ngSelectInstance.isOpen.set(false);
      this.selectedItem = undefined;
      this.toggleTopMenuClass();
    }

    (document.activeElement as HTMLInputElement).blur();
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
    this.markable$.pipe(first()).subscribe(() => {
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
    if (item instanceof WorkPackageResource) {
      window.location.href = this.wpPath(item.displayId);
    } else if (item) {
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
    return item.id === undefined || item.subject.toLowerCase().includes(term.toLowerCase());
  }

  private autocompleteWorkPackages():Observable<(WorkPackageResource|SearchOptionItem)[]> {
    // ng-select v21 initializes _searchTerm as null (signal). Treat null as '' so that
    // the initial typeahead emission triggers loadRecentItems() instead of returning empty.
    const query = this.searchTerm ?? '';
    if (/^\s+$/.test(query)) {
      return of([]);
    }

    if (!query.length) {
      return this.loadRecentItems();
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
        map((collection) => this.searchResultsToOptions(collection.elements, hashFreeQuery))
      );
  }

  private loadRecentItems() {
    return this.recentItemsService.recentItems$.pipe(
      switchMap((wpIds) => {
        // It is needed, because otherwise we get infinite spin running
        // in the searchbar with no recent workpackages IDs inside localStorage
        if (wpIds.length === 0) {
          return of([]);
        }


        // Ensure we only load the five recent items
        // in case none of them are available in the cache
        const filters = new ApiV3FilterBuilder().add('id', '=', wpIds);
        const params = {
          offset: '1',
          pageSize: '5',
          valid_subset: 'true',
        };

        return this
          .apiV3Service
          .work_packages
          .filtered(filters, params)
          .get()
          .pipe(
            map((collection) => {
              // In case none of the wpIds exist anymore or are not accessible
              // this API call would return five arbitrary work packages, as that's the way valid_subset works
              return collection.elements.filter((wp) => wpIds.includes(wp.id!));
            })
          );
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
      .filterByTypeaheadOrId(query, idOnly, { pageSize: '20' });
  }

  private searchResultsToOptions(results:WorkPackageResource[], query:string) {
    const searchOptions = this.detailedSearchOptions();
    // If we have a direct hit, we choose it to be the selected element.
    this.selectedItem = results.find((wp) => wp.id?.toString() === query) || searchOptions[0];

    if (this.selectedItem instanceof WorkPackageResource) {
      void announce(this.I18n.t('js.global_search.direct_hit_available'), { politeness: 'polite' });
      this.setMarkedOption();
    }
    else {
      const resultCount = results.length + searchOptions.length;
      void announce(this.I18n.t('js.global_search.items_available', { count: resultCount }), { politeness: 'polite' });
    }

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
    if (this.currentScope === 'current_project') {
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
    this.ngSelectComponent.ngSelectInstance.itemsList.markItem(this.selectedItem as NgOption);

    this.cdRef.detectChanges();
  }

  private searchInScope(scope:string):void {
    switch (scope) {
      case 'all_projects': {
        this.submitNonEmptySearch('all');
        break;
      }
      case 'current_project': {
        this.submitNonEmptySearch('current_project');
        break;
      }
      case 'current_project_and_all_descendants': {
        this.submitNonEmptySearch('');
        break;
      }
      default: // Do nothing
        break;
    }
  }

  public submitNonEmptySearch(scope:string):void {
    if (this.currentValue.length > 0) {
      this.ngSelectComponent.ngSelectInstance.close();
      this.globalSearchService.submitSearch(this.currentValue, scope);
    }
  }

  private get currentScope():string {
    const params = new URLSearchParams(window.location.search);
    const serviceScope = params.get('scope') || '';
    return (serviceScope === '') ? 'current_project_and_all_descendants' : serviceScope;
  }

  private get currentQuery():string|null {
    const params = new URLSearchParams(window.location.search);
    return params.get('q');
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
