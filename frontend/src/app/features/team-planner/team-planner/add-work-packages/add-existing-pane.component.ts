import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostBinding,
  OnDestroy,
  OnInit,
  ViewChild,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import {
  BehaviorSubject,
  combineLatest,
  Observable,
  of,
} from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  map,
  startWith,
  switchMap,
} from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CalendarDragDropService } from 'core-app/features/team-planner/team-planner/calendar-drag-drop.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { StateService } from '@uirouter/core';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { teamPlannerEventRemoved } from 'core-app/features/team-planner/team-planner/planner/team-planner.actions';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import { OpWorkPackagesCalendarService } from 'core-app/features/calendar/op-work-packages-calendar.service';

@Component({
  selector: 'op-add-existing-pane',
  templateUrl: './add-existing-pane.component.html',
  styleUrls: ['./add-existing-pane.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AddExistingPaneComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @HostBinding('class.op-add-existing-pane') className = true;

  @ViewChild('container') container:ElementRef;

  @ViewChild('container')
  set dragContainer(v:ElementRef|undefined) {
    // ViewChild reference may be undefined initially
    // due to ngIf
    if (v !== undefined) {
      this.calendarDrag.destroyDrake();
      this.calendarDrag.registerDrag(v, '.op-add-existing-pane--wp');
    }
  }

  /** Input for search requests */
  public searchString$ = new BehaviorSubject<string>('');

  isEmpty$ = new BehaviorSubject<boolean>(true);

  isLoading$ = new BehaviorSubject<boolean>(false);

  noResultsFound$ = this.isEmpty$
    .pipe(
      map((resultEmpty) => {
        if (this.searchString$.getValue().length === 0) {
          return { showImage: true, text: this.text.empty_state };
        }

        if (resultEmpty) {
          return { showImage: false, text: this.text.no_results };
        }

        return {};
      }),
    );

  currentWorkPackages$ = combineLatest([
    this.calendarDrag.draggableWorkPackages$,
    this.querySpace.results.values$(),
  ])
    .pipe(
      map(([draggable, rendered]) => {
        const renderedIds = rendered.elements.map((el) => el.id as string);
        return draggable.filter((wp) => !renderedIds.includes(wp.id as string));
      }),
    );

  workPackageRemoved$:Observable<unknown> = this
    .actions$
    .ofType(teamPlannerEventRemoved)
    .pipe(
      startWith(null),
    );

  text = {
    empty_state: this.I18n.t('js.team_planner.quick_add.empty_state'),
    placeholder: this.I18n.t('js.team_planner.quick_add.search_placeholder'),
    no_results: this.I18n.t('js.autocompleter.notFoundText'),
  };

  image = {
    empty_state: imagePath('team-planner/add-existing-pane--empty-state.gif'),
  };

  constructor(
    private readonly querySpace:IsolatedQuerySpace,
    private I18n:I18nService,
    private readonly apiV3Service:ApiV3Service,
    private readonly notificationService:WorkPackageNotificationService,
    private readonly currentProject:CurrentProjectService,
    private readonly urlParamsHelper:UrlParamsHelperService,
    private readonly workPackagesCalendar:OpWorkPackagesCalendarService,
    private readonly calendarDrag:CalendarDragDropService,
    private readonly $state:StateService,
    private readonly actions$:ActionsService,
    private readonly wpFilters:WorkPackageViewFiltersService,
  ) {
    super();
  }

  ngOnInit():void {
    combineLatest([
      this
        .searchString$
        .pipe(
          distinctUntilChanged(),
          debounceTime(500),
        ),
      this
        .wpFilters
        .updates$()
        .pipe(
          startWith(null),
        ),
      this.workPackageRemoved$,
    ])
      .pipe(
        this.untilDestroyed(),
        map(([searchString]) => searchString),
        switchMap((searchString:string) => this.searchWorkPackages(searchString)),
      )
      .subscribe((results) => {
        this.calendarDrag.draggableWorkPackages$.next(results);

        this.isEmpty$.next(results.length === 0);
        this.isLoading$.next(false);
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.calendarDrag.destroyDrake();
  }

  searchWorkPackages(searchString:string):Observable<WorkPackageResource[]> {
    this.isLoading$.next(true);

    // Return when the search string is empty
    if (searchString.length === 0) {
      this.isLoading$.next(false);
      this.isEmpty$.next(true);

      return of([]);
    }

    // Add any visible global filters
    const activeFilters = this.wpFilters.currentlyVisibleFilters;
    const filters:ApiV3FilterBuilder = this.urlParamsHelper.filterBuilderFrom(activeFilters);

    filters.add('typeahead', '**', [searchString]);

    // Add the existing filter, if any
    this.addExistingFilters(filters);

    return this
      .apiV3Service
      .withOptionalProject(this.currentProject.id)
      .work_packages
      .filtered(filters, { pageSize: '-1' })
      .get()
      .pipe(
        map((collection) => collection.elements),
        catchError((error:unknown) => {
          this.notificationService.handleRawError(error);
          return of([]);
        }),
        this.untilDestroyed(),
      );
  }

  clearInput():void {
    this.searchString$.next('');
  }

  get isSearching():boolean {
    return this.searchString$.value !== '';
  }

  showDisabledText(wp:WorkPackageResource):{ text:string, orientation:'left'|'right' } {
    return {
      text: this.calendarDrag.workPackageDisabledExplanation(wp),
      orientation: 'left',
    };
  }

  openStateLink(event:{ workPackageId:string; requestedState:string }):void {
    void this.$state.go(
      `${splitViewRoute(this.$state)}.tabs`,
      { workPackageId: event.workPackageId, tabIdentifier: 'overview' },
    );
  }

  private addExistingFilters(filters:ApiV3FilterBuilder) {
    const query = this.querySpace.query.value;
    if (query?.filters) {
      const currentFilters = this.urlParamsHelper.buildV3GetFilters(query.filters);

      currentFilters.forEach((filter) => {
        Object.keys(filter).forEach((name) => {
          if (name !== 'assignee' && name !== 'datesInterval') {
            filters.add(name, filter[name].operator, filter[name].values);
          }
        });
      });
    }
  }
}
