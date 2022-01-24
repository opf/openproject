import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostBinding,
  OnInit,
  ViewChild,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import {
  BehaviorSubject,
  Observable,
  of,
  Subject,
} from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  map,
  switchMap,
  tap,
} from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CalendarDragDropService } from 'core-app/features/team-planner/team-planner/calendar-drag-drop.service';
import { input } from 'reactivestates';

@Component({
  selector: 'op-add-existing-pane',
  templateUrl: './add-existing-pane.component.html',
  styleUrls: ['./add-existing-pane.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AddExistingPaneComponent extends UntilDestroyedMixin implements OnInit {
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

  /** Observable to the current search filter term */
  public searchString = input<string>('');

  /** Input for search requests */
  public searchStringChanged$:Subject<string> = new Subject<string>();

  isEmpty$ = new BehaviorSubject<boolean>(true);

  isLoading$ = new BehaviorSubject<boolean>(false);

  currentWorkPackages$ = this.calendarDrag.draggableWorkPackages$;

  text = {
    empty_state: this.I18n.t('js.team_planner.quick_add.empty_state'),
    placeholder: this.I18n.t('js.team_planner.quick_add.search_placeholder'),
  };

  image = {
    empty_state: imagePath('team-planner/add-existing-pane--empty-state.svg'),
  };

  constructor(
    private readonly querySpace:IsolatedQuerySpace,
    private I18n:I18nService,
    private readonly apiV3Service:ApiV3Service,
    private readonly notificationService:WorkPackageNotificationService,
    private readonly currentProject:CurrentProjectService,
    private readonly urlParamsHelper:UrlParamsHelperService,
    private readonly calendarDrag:CalendarDragDropService,
  ) {
    super();
  }

  ngOnInit():void {
    this.searchStringChanged$
      .pipe(
        this.untilDestroyed(),
        distinctUntilChanged(),
        debounceTime(500),
        tap((val) => this.searchString.putValue(val)),
        switchMap((searchString:string) => this.searchWorkPackages(searchString)),
      ).subscribe((results) => {
        this.calendarDrag.draggableWorkPackages$.next(results);

        this.isEmpty$.next(results.length === 0);
        this.isLoading$.next(false);
      });
  }

  // eslint-disable-next-line @angular-eslint/use-lifecycle-interface
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

    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    const queryResults = this.querySpace.results.value;

    filters.add('subjectOrId', '**', [searchString]);

    if (queryResults && queryResults.elements.length > 0) {
      filters.add('id', '!', queryResults.elements.map((wp:WorkPackageResource) => wp.id || ''));
    }

    // Add the existing filter, if any
    this.addExistingFilters(filters);

    return this
      .apiV3Service
      .withOptionalProject(this.currentProject.id)
      .work_packages
      .filtered(filters)
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
    this.searchStringChanged$.next('');
  }

  get isSearching():boolean {
    return this.searchString.value !== '';
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
