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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, HostListener, Input, OnDestroy, ViewChild, ViewEncapsulation, inject } from '@angular/core';
import { BehaviorSubject, forkJoin, Observable, of } from 'rxjs';
import { catchError, first, map, switchMap } from 'rxjs/operators';
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
import { MeetingResource } from 'core-app/features/hal/resources/meeting-resource';
import { WikiPageResource } from 'core-app/features/hal/resources/wiki-page-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';

export type SearchResultType = 'all'|'work_packages'|'meetings'|'wiki_pages';
type GlobalSearchResult = WorkPackageResource|MeetingResource|WikiPageResource;
type ProjectScope = 'all_projects'|'current_project'|'current_project_and_all_descendants';
type LastUpdatedFilter = 'any_time'|'today'|'yesterday'|'past_7_days'|'past_30_days'|'past_year';
type WorkPackageStatusFilter = 'all'|'open'|'closed';
type WorkPackageInvolvementFilter = 'all'|'assigned_to_me'|'created_by_me'|'accountable';
type MeetingTimeFilter = 'all'|'upcoming'|'past';
type MeetingInvolvementFilter = 'all'|'invited'|'created_by_me'|'attended';

export function lastUpdatedRange(
  filter:LastUpdatedFilter,
  now = new Date(),
):[string, string]|undefined {
  if (filter === 'any_time') {
    return undefined;
  }

  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);

  if (filter === 'today') {
    return [startOfToday.toISOString(), ''];
  }

  if (filter === 'yesterday') {
    const startOfYesterday = new Date(startOfToday);
    startOfYesterday.setDate(startOfYesterday.getDate() - 1);
    return [startOfYesterday.toISOString(), startOfToday.toISOString()];
  }

  const start = new Date(now);
  if (filter === 'past_year') {
    start.setFullYear(start.getFullYear() - 1);
  } else {
    start.setDate(start.getDate() - (filter === 'past_7_days' ? 7 : 30));
  }

  return [start.toISOString(), ''];
}

export function searchResultMatchesType(resultType:SearchResultType, item:GlobalSearchResult):boolean {
  return resultType === 'all'
    || (resultType === 'work_packages' && item instanceof WorkPackageResource)
    || (resultType === 'meetings' && item instanceof MeetingResource)
    || (resultType === 'wiki_pages' && item instanceof WikiPageResource);
}

type GlobalSearchItem = GlobalSearchResult;

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
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
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
  readonly currentUserService = inject(CurrentUserService);

  @Input() public placeholder:string;

  @ViewChild('btn', { static: true }) btn:ElementRef<HTMLButtonElement>;

  @ViewChild(OpAutocompleterComponent, { static: true }) public ngSelectComponent:OpAutocompleterComponent;

  public expanded = false;

  private _searchTermInitialized = false;

  private currentSearchResults:GlobalSearchResult[] = [];
  private currentResultQuery = '';
  private projectScopeInteraction = false;
  private filterRefreshVersion = 0;

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

  public activeResultType:SearchResultType = 'all';
  public readonly resultTypes:SearchResultType[] = ['all', 'work_packages', 'meetings', 'wiki_pages'];
  public readonly lastUpdatedFilters:LastUpdatedFilter[] = [
    'any_time', 'today', 'yesterday', 'past_7_days', 'past_30_days', 'past_year',
  ];

  public readonly workPackageStatusFilters:WorkPackageStatusFilter[] = ['all', 'open', 'closed'];
  public readonly workPackageInvolvementFilters:WorkPackageInvolvementFilter[] = [
    'all', 'assigned_to_me', 'created_by_me', 'accountable',
  ];

  public readonly meetingTimeFilters:MeetingTimeFilter[] = ['all', 'upcoming', 'past'];
  public readonly meetingInvolvementFilters:MeetingInvolvementFilter[] = [
    'all', 'invited', 'created_by_me', 'attended',
  ];

  public selectedLastUpdatedFilter:LastUpdatedFilter = 'any_time';
  public selectedWorkPackageStatusFilter:WorkPackageStatusFilter = 'all';
  public selectedWorkPackageInvolvementFilter:WorkPackageInvolvementFilter = 'all';
  public selectedMeetingTimeFilter:MeetingTimeFilter = 'all';
  public selectedMeetingInvolvementFilter:MeetingInvolvementFilter = 'all';
  public selectedProjectScope:ProjectScope;

  getAutocompleterData = ():Observable<unknown[]> => this.autocompleteGlobalSearch();

  public autocompleterOptions = {
    filters: [],
    resource: 'work_packages',
    searchKey: 'subjectOrId',
    getOptionsFn: this.getAutocompleterData,
  };

  /** Remember the item that best matches the query.
   * That way, it will be highlighted (as we manually mark the selected item) and we can handle enter.
   * */
  public selectedItem:GlobalSearchItem|undefined = undefined;

  /** Remember the current value */
  public currentValue = '';

  public isFocusedDirectly = !!this.currentQuery && this.selectedItem instanceof HalResource;

  public liveMessage = '';

  private unregisterGlobalListener:(() => unknown)|undefined;

  public text:Record<string, string> = {
    accountable: this.I18n.t('js.global_search.quick_filters.accountable'),
    all: this.I18n.t('js.label_all_uppercase'),
    all_projects: this.I18n.t('js.global_search.all_projects'),
    any_time: this.I18n.t('js.global_search.quick_filters.any_time'),
    assigned_to_me: this.I18n.t('js.work_packages.default_queries.assigned_to_me'),
    attended: this.I18n.t('js.global_search.quick_filters.attended'),
    close_search: this.I18n.t('js.global_search.close_search'),
    closed: this.I18n.t('js.global_search.quick_filters.closed'),
    created_by_me: this.I18n.t('js.work_packages.default_queries.created_by_me'),
    current_project_and_all_descendants: this.I18n.t('js.global_search.current_project_and_all_descendants'),
    current_project: this.I18n.t('js.global_search.current_project'),
    recently_viewed: this.I18n.t('js.global_search.recently_viewed'),
    search: this.I18n.t('js.autocompleter.search'),
    work_packages: this.I18n.t('js.label_work_package_plural'),
    meetings: this.I18n.t('js.label_meetings'),
    meeting_date: this.I18n.t('js.global_search.quick_filters.meeting_date'),
    involvement: this.I18n.t('js.global_search.quick_filters.involvement'),
    invited: this.I18n.t('js.global_search.quick_filters.invited'),
    last_updated: this.I18n.t('js.label_last_updated_on'),
    open: this.I18n.t('js.global_search.quick_filters.open'),
    past: this.I18n.t('js.global_search.quick_filters.past'),
    past_7_days: this.I18n.t('js.global_search.quick_filters.past_7_days'),
    past_30_days: this.I18n.t('js.global_search.quick_filters.past_30_days'),
    past_year: this.I18n.t('js.global_search.quick_filters.past_year'),
    project: this.I18n.t('js.label_project'),
    status: this.I18n.t('js.work_packages.properties.status'),
    today: this.I18n.t('js.label_today'),
    upcoming: this.I18n.t('js.global_search.quick_filters.upcoming'),
    wiki_pages: this.I18n.t('js.global_search.wiki_pages'),
    yesterday: this.I18n.t('js.global_search.quick_filters.yesterday'),
  };

  constructor() {
    populateInputsFromDataset(this);
    this.selectedProjectScope = this.currentProjectService.path
      ? this.currentScope
      : 'all_projects';
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
    if (insideOrSelf(this.btn.nativeElement, event.target as HTMLElement)) {
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
        this.searchInScope(this.selectedProjectScope);
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

  public search(_$event:unknown):void {
    this.filterRefreshVersion += 1;
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

  public onFocusOut(event?:FocusEvent):void {
    const nextFocusedElement = event?.relatedTarget;
    if (
      this.projectScopeInteraction
      || (nextFocusedElement instanceof Node && this.elementRef.nativeElement.contains(nextFocusedElement))
    ) {
      return;
    }

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

  public followItem(item:GlobalSearchItem|undefined):void {
    this.selectedItem = item;
    if (this.isWikiPage(item)) {
      window.location.href = String(item.showWikiPagePath);
    } else if (this.isWorkPackage(item)) {
      window.location.href = this.wpPath(item.displayId);
    } else if (this.isMeeting(item)) {
      window.location.href = this.pathHelperService.meetingPath(item.id!);
    }
  }

  public followSelectedItem():void {
    if (this.selectedItem) {
      this.followItem(this.selectedItem);
    }
  }

  public customSearchFn(term:string, item:GlobalSearchItem):boolean {
    if (!(item instanceof HalResource)) {
      return true;
    }

    if (!this.isActiveResult(item)) {
      return false;
    }

    return !this.isWorkPackage(item)
      || item.subject.toLowerCase().includes(term.toLowerCase());
  }

  public selectResultType(resultType:SearchResultType):void {
    this.activeResultType = resultType;
    this.refreshFilteredResults();
  }

  public selectLastUpdatedFilter(filter:LastUpdatedFilter):void {
    this.selectedLastUpdatedFilter = filter;
    this.refreshFilteredResults();
  }

  public selectWorkPackageStatusFilter(filter:WorkPackageStatusFilter):void {
    this.selectedWorkPackageStatusFilter = filter;
    this.refreshFilteredResults();
  }

  public selectWorkPackageInvolvementFilter(filter:WorkPackageInvolvementFilter):void {
    this.selectedWorkPackageInvolvementFilter = filter;
    this.refreshFilteredResults();
  }

  public selectMeetingTimeFilter(filter:MeetingTimeFilter):void {
    this.selectedMeetingTimeFilter = filter;
    this.refreshFilteredResults();
  }

  public selectMeetingInvolvementFilter(filter:MeetingInvolvementFilter):void {
    this.selectedMeetingInvolvementFilter = filter;
    this.refreshFilteredResults();
  }

  public selectProjectScope(event:Event):void {
    this.selectedProjectScope = (event.target as HTMLSelectElement).value as ProjectScope;
  }

  public onProjectScopeMouseDown(event:MouseEvent):void {
    this.projectScopeInteraction = true;
    event.stopPropagation();
  }

  public onProjectScopeBlur():void {
    this.projectScopeInteraction = false;
  }

  public get projectScopes():ProjectScope[] {
    return this.currentProjectService.path
      ? ['current_project_and_all_descendants', 'current_project', 'all_projects']
      : ['all_projects'];
  }

  public resultPath(item:GlobalSearchResult):string {
    if (this.isWikiPage(item)) {
      return String(item.showWikiPagePath);
    }

    if (this.isWorkPackage(item)) {
      return this.wpPath(item.displayId);
    }

    if (this.isMeeting(item)) {
      return this.pathHelperService.meetingPath(item.id!);
    }

    return '#';
  }

  public resultTitle(item:GlobalSearchResult):string {
    return this.isWorkPackage(item) ? item.subject : item.title;
  }

  public resultIcon(item:GlobalSearchResult):string {
    if (this.isWorkPackage(item)) {
      return 'op-view-list';
    }

    return this.isMeeting(item) ? 'comment-discussion' : 'book';
  }

  public resultTypeLabel(item:GlobalSearchResult):string {
    if (this.isWorkPackage(item)) {
      return this.text.work_packages;
    }

    return this.isMeeting(item) ? this.text.meetings : this.text.wiki_pages;
  }

  public isWorkPackage(item:GlobalSearchItem|undefined):item is WorkPackageResource {
    return item instanceof WorkPackageResource;
  }

  public isMeeting(item:GlobalSearchItem|undefined):item is MeetingResource {
    return item instanceof MeetingResource;
  }

  public isWikiPage(item:GlobalSearchItem|undefined):item is WikiPageResource {
    return item instanceof WikiPageResource;
  }

  public redirectToResult(item:GlobalSearchResult, event:MouseEvent):boolean {
    event.stopImmediatePropagation();
    if (isClickedWithModifier(event)) {
      return true;
    }

    window.location.href = this.resultPath(item);
    event.preventDefault();
    return false;
  }

  private autocompleteGlobalSearch():Observable<GlobalSearchItem[]> {
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

    const workPackageFilters = this.workPackageFilters();
    const meetingFilters = new ApiV3FilterBuilder().add('search', '**', [query]);
    const wikiPageFilters = new ApiV3FilterBuilder().add('search', '**', [query]);
    this.applyLastUpdatedFilter(workPackageFilters);
    this.applyLastUpdatedFilter(meetingFilters);
    this.applyLastUpdatedFilter(wikiPageFilters);
    this.applyMeetingQuickFilters(meetingFilters);
    const params = { pageSize: '20' };

    return forkJoin({
      workPackages: this.fetchSearchResults(hashFreeQuery, hashFreeQuery !== query, workPackageFilters).get().pipe(
        map((collection) => collection.elements),
      ),
      meetings: this.apiV3Service.meetings.filtered(meetingFilters, params).get().pipe(
        map((collection:CollectionResource<HalResource>) => collection.elements.filter(
          (item):item is MeetingResource => item instanceof MeetingResource,
        )),
        catchError(() => of([] as MeetingResource[])),
      ),
      wikiPages: this.apiV3Service.wiki_pages.filtered(wikiPageFilters, params).get().pipe(
        map((collection:CollectionResource<HalResource>) => collection.elements.filter(
          (item):item is WikiPageResource => item instanceof WikiPageResource,
        )),
        catchError(() => of([] as WikiPageResource[])),
      ),
    }).pipe(
      map(({ workPackages, meetings, wikiPages }) => {
        this.currentSearchResults = [...workPackages, ...meetings, ...wikiPages];
        this.currentResultQuery = hashFreeQuery;

        return this.searchResultsToOptions(this.currentSearchResults, this.currentResultQuery);
      }),
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
        const filters = this.workPackageFilters().add('id', '=', wpIds);
        this.applyLastUpdatedFilter(filters);
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
              const recentWorkPackages = collection.elements.filter((wp) => wpIds.includes(wp.id!));
              this.currentSearchResults = recentWorkPackages;
              this.currentResultQuery = '';

              return this.searchResultsToOptions(recentWorkPackages, '');
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

  private fetchSearchResults(
    query:string,
    idOnly:boolean,
    filters:ApiV3FilterBuilder,
  ):ApiV3WorkPackageCachedSubresource {
    return this
      .apiV3Service
      .work_packages
      .filterByTypeaheadOrId(query, idOnly, { pageSize: '20' }, filters);
  }

  private refreshFilteredResults():void {
    const refreshVersion = this.filterRefreshVersion + 1;
    this.filterRefreshVersion = refreshVersion;
    this.ngSelectComponent.loading$.next(true);
    this.ngSelectComponent.updateItems([]);

    this.autocompleteGlobalSearch().pipe(first()).subscribe({
      next: (items) => {
        if (refreshVersion !== this.filterRefreshVersion) {
          return;
        }

        this.ngSelectComponent.updateItems(items);
        this.ngSelectComponent.loading$.next(false);
        this.cdRef.detectChanges();
      },
      error: () => {
        if (refreshVersion === this.filterRefreshVersion) {
          this.ngSelectComponent.loading$.next(false);
          this.cdRef.detectChanges();
        }
      },
    });
  }

  private workPackageFilters():ApiV3FilterBuilder {
    const filters = new ApiV3FilterBuilder();
    if (this.activeResultType !== 'work_packages') {
      return filters;
    }

    if (this.selectedWorkPackageStatusFilter === 'open') {
      filters.add('status', 'o', []);
    } else if (this.selectedWorkPackageStatusFilter === 'closed') {
      filters.add('status', 'c', []);
    }

    const involvementFilters = {
      assigned_to_me: 'assignee',
      created_by_me: 'author',
      accountable: 'responsible',
    } as const;
    if (this.selectedWorkPackageInvolvementFilter !== 'all') {
      filters.add(involvementFilters[this.selectedWorkPackageInvolvementFilter], '=', ['me']);
    }

    return filters;
  }

  private applyMeetingQuickFilters(filters:ApiV3FilterBuilder):void {
    if (this.activeResultType !== 'meetings') {
      return;
    }

    if (this.selectedMeetingTimeFilter !== 'all') {
      filters.add('time', this.selectedMeetingTimeFilter, []);
    }

    const userId = this.currentUserService.userId;
    const involvementFilters = {
      invited: 'invitedUser',
      created_by_me: 'author',
      attended: 'attendedUser',
    } as const;
    if (userId && this.selectedMeetingInvolvementFilter !== 'all') {
      filters.add(involvementFilters[this.selectedMeetingInvolvementFilter], '=', [userId]);
    }
  }

  private applyLastUpdatedFilter(filters:ApiV3FilterBuilder):void {
    const range = lastUpdatedRange(this.selectedLastUpdatedFilter);
    if (range) {
      filters.add('updatedAt', '<>d', range);
    }
  }

  private searchResultsToOptions(results:GlobalSearchResult[], query:string) {
    // If we have a direct hit, we choose it to be the selected element.
    const visibleResults = results.filter((item) => this.isActiveResult(item));
    const directHit = ['all', 'work_packages'].includes(this.activeResultType)
      ? results.find((item) => item instanceof WorkPackageResource && item.id?.toString() === query)
      : undefined;
    this.selectedItem = directHit;

    if (directHit) {
      void announce(this.I18n.t('js.global_search.direct_hit_available'), { politeness: 'polite' });
      this.setMarkedOption();
    }
    else {
      const resultCount = visibleResults.length;
      void announce(this.I18n.t('js.global_search.items_available', { count: resultCount }), { politeness: 'polite' });
    }

    return [
      ...visibleResults,
    ];
  }

  private isActiveResult(item:GlobalSearchResult):boolean {
    return searchResultMatchesType(this.activeResultType, item);
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

  private searchInScope(scope:ProjectScope):void {
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
      this.globalSearchService.submitSearch(this.currentValue, scope, this.activeResultType);
    }
  }

  private get currentScope():ProjectScope {
    const params = new URLSearchParams(window.location.search);
    const serviceScope = params.get('scope');
    return serviceScope === 'all' || serviceScope === 'all_projects'
      ? 'all_projects'
      : serviceScope === 'current_project'
        ? 'current_project'
        : 'current_project_and_all_descendants';
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
