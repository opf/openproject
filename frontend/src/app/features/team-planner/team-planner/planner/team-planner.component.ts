import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  OnDestroy,
  OnInit,
  TemplateRef,
  ViewChild,
} from '@angular/core';
import {
  CalendarOptions,
  EventInput,
} from '@fullcalendar/core';
import {
  Observable,
  Subject,
} from 'rxjs';
import {
  debounceTime,
  mergeMap,
  map,
  filter,
  distinctUntilChanged,
} from 'rxjs/operators';
import { take } from 'rxjs/internal/operators/take';
import { EventClickArg } from '@fullcalendar/common';
import { StateService } from '@uirouter/angular';
import { ResourceLabelContentArg } from '@fullcalendar/resource-common';
import resourceTimelinePlugin from '@fullcalendar/resource-timeline';
import { FullCalendarComponent } from '@fullcalendar/angular';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { EventViewLookupService } from 'core-app/features/team-planner/team-planner/planner/event-view-lookup.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { Apiv3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';

@Component({
  selector: 'op-team-planner',
  templateUrl: './team-planner.component.html',
  styleUrls: ['./team-planner.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    EventViewLookupService,
  ],
})
export class TeamPlannerComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @ViewChild('ucCalendar', { read: ElementRef })
  set ucCalendarElement(v:ElementRef|undefined) {
    if (!v) {
      return;
    }

    if (!this.resizeObserver) {
      this.resizeObserver = new ResizeObserver(() => this.resizeSubject.next());
    }

    this.resizeObserver.observe(v.nativeElement);
  }

  @ViewChild('resourceContent') resourceContent:TemplateRef<unknown>;

  @ViewChild('assigneeAutocompleter') assigneeAutocompleter:TemplateRef<unknown>;

  private resizeObserver:ResizeObserver;

  private resizeSubject = new Subject<unknown>();

  private principalIds$ = this.wpTableFilters
      .live$()
      .pipe(
        this.untilDestroyed(),
        map((queryFilters) => {
          const assigneeFilter = queryFilters.find((filter) => filter._type === 'AssigneeQueryFilter');
          return ((assigneeFilter?.values || []) as HalResource[]).map(p => p.id);
        })
      );

  private params$ = this.principalIds$
      .pipe(
        this.untilDestroyed(),
        filter((ids) => ids.length > 0),
        map((ids) => ({
          filters: [['id', '=', ids]]
        }) as Apiv3ListParameters),
      );

  calendarOptions$ = new Subject<CalendarOptions>();

  projectIdentifier:string|null = null;

  assignees:HalResource[] = [];
  
  text = {
    assignees: this.I18n.t('js.team_planner.label_assignee_plural'),
  };

  principals$ = this.principalIds$
    .pipe(
        this.untilDestroyed(),
        mergeMap((ids:string[]) => this.principalsResourceService.query.byIds(ids)),
        debounceTime(50),
        distinctUntilChanged((prev, curr) => prev.length === curr.length && prev.length === 0),
    );

  constructor(
    private elementRef:ElementRef,
    private $state:StateService,
    private configuration:ConfigurationService,
    private apiV3Service:APIV3Service,
    private principalsResourceService:PrincipalsResourceService,
    private wpTableFilters:WorkPackageViewFiltersService,
    private wpListService:WorkPackagesListService,
    private querySpace:IsolatedQuerySpace,
    private schemaCache:SchemaCacheService,
    private currentProject:CurrentProjectService,
    private viewLookup:EventViewLookupService,
    private I18n:I18nService,
  ) {
    super();
  }

  ngOnInit():void {
    this.initializeCalendar();
    this.projectIdentifier = this.currentProject.identifier;

    this
      .querySpace
      .results
      .values$()
      .pipe(this.untilDestroyed())
      .subscribe(() => {
        this.renderCurrent();
      });

    this.resizeSubject
      .pipe(this.untilDestroyed())
      .subscribe(() => {
        this.ucCalendar.getApi().updateSize();
      });

    this.params$
      .pipe(this.untilDestroyed())
      .subscribe((params) => {
        this.principalsResourceService.fetchPrincipals(params).subscribe();
      });
      
    this.principals$
      .pipe(this.untilDestroyed())
      .subscribe((principals) => {
        const api = this.ucCalendar.getApi();
        
        api.getResources().forEach((resource) => resource.remove());

        principals.forEach((principal) => api.addResource({
          principal,
          id: principal.id as string,
          title: principal.name,
        }));
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.resizeObserver?.disconnect();
  }

  public calendarEventsFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):void|PromiseLike<EventInput[]> {
    this
      .currentWorkPackages()
      .toPromise()
      .then((workPackages) => {
        const events = this.mapToCalendarEvents(workPackages);
        successCallback(events);
      })
      .catch(failureCallback);

    this.updateTimeframe(fetchInfo);
  }

  private currentWorkPackages():Observable<WorkPackageResource[]> {
    return this
      .querySpace
      .results
      .values$()
      .pipe(
        take(1),
        map((collection:CollectionResource<WorkPackageResource>) => (
          collection
            .elements
            .map((wp) => this.apiV3Service.work_packages.cache.current(wp.id as string, wp) as WorkPackageResource)
        )),
      );
  }

  private initializeCalendar() {
    void this.configuration.initialized
      .then(() => {
        this.calendarOptions$.next({
          schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
          editable: false,
          locale: this.I18n.locale,
          fixedWeekCount: false,
          firstDay: this.configuration.startOfWeek(),
          timeZone: this.configuration.isTimezoneSet() ? this.configuration.timezone() : 'local',
          plugins: [
            resourceTimelinePlugin,
          ],
          headerToolbar: {
            left: 'prev,next today',
            center: 'title',
            right: '',
          },
          titleFormat: {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
          },
          initialView: 'resourceTimelineWeekDaysOnly',
          height: 'auto',
          views: {
            resourceTimelineWeekDaysOnly: {
              type: 'resourceTimeline',
              duration: { weeks: 1 },
              slotDuration: { days: 1 },
              slotLabelFormat: [
                {
                  weekday: 'long',
                  day: '2-digit',
                },
              ],
              resourceAreaColumns: [
                {
                  field: 'title',
                  headerContent: this.text.assignees,
                },
              ],
            },
          },
          events: this.calendarEventsFunction.bind(this) as unknown,
          resources: [],
          eventClick: this.openSplitView.bind(this) as unknown,
          resourceLabelContent: (data:ResourceLabelContentArg) => this.renderTemplate(this.resourceContent, data.resource.id, data),
          resourceLabelWillUnmount: (data:ResourceLabelContentArg) => this.unrenderTemplate(data.resource.id),
        } as CalendarOptions);
      });
  }

  renderTemplate(template:TemplateRef<unknown>, id:string, data:ResourceLabelContentArg):{ domNodes:unknown[] } {
    const ref = this.viewLookup.getView(template, id, data);
    return { domNodes: ref.rootNodes };
  }

  unrenderTemplate(id:string):void {
    this.viewLookup.destroyView(id);
  }

  public updateTimeframe(fetchInfo:{ start:Date, end:Date, timeZone:string }):void {
    const filtersEmpty = this.wpTableFilters.isEmpty;

    if (filtersEmpty && this.querySpace.query.value) {
      // nothing to do
      return;
    }

    const startDate = moment(fetchInfo.start).format('YYYY-MM-DD');
    const endDate = moment(fetchInfo.end).format('YYYY-MM-DD');

    if (filtersEmpty) {
      let queryProps = this.defaultQueryProps(startDate, endDate);

      if (this.$state.params.query_props) {
        queryProps = decodeURIComponent(this.$state.params.query_props || '');
      }

      void this
        .wpListService
        .fromQueryParams({ query_props: queryProps }, this.projectIdentifier || undefined)
        .toPromise();
    } else {
      this.wpTableFilters.modify('datesInterval', (datesIntervalFilter) => {
        // eslint-disable-next-line no-param-reassign
        datesIntervalFilter.values[0] = startDate;
        // eslint-disable-next-line no-param-reassign
        datesIntervalFilter.values[1] = endDate;
      });
    }
  }

  public showAssigneeAddRow() {
    const api = this.ucCalendar.getApi();
    api.addResource({
      id: 'NEW',
      title: 'Add Assignee',
      principal: null,
    });
  }

  public addAssignee(principal:HalResource) {
    const api = this.ucCalendar.getApi();
    api.getResourceById('NEW')?.remove();

    const modifyFilter = (assigneeFilter:QueryFilterInstanceResource) => {
      // eslint-disable-next-line no-param-reassign
      assigneeFilter.values = [
        ...assigneeFilter.values as HalResource[],
        principal,
      ];
    };


    if (this.wpTableFilters.findIndex('assignee') === -1) {
      // Replace actually also instantiates if it does not exist, which is handy here
      this.wpTableFilters.replace('assignee', modifyFilter.bind(this));
    } else {
      this.wpTableFilters.modify('assignee', modifyFilter.bind(this));
    }
  }

  private openSplitView(event:EventClickArg) {
    const workPackage = event.event.extendedProps.workPackage as WorkPackageResource;

    void this.$state.go(
      `${splitViewRoute(this.$state)}.tabs`,
      { workPackageId: workPackage.id, tabIdentifier: 'overview' },
    );
  }

  /**
   * Renders the currently loaded set of items
   */
  private renderCurrent() {
    this.ucCalendar.getApi().refetchEvents();
    this.ucCalendar.getApi().refetchResources();
  }

  private mapToCalendarEvents(workPackages:WorkPackageResource[]):EventInput[] {
    return workPackages
      .map((workPackage:WorkPackageResource):EventInput|undefined => {
        if (!workPackage.assignee) {
          return undefined;
        }

        const startDate = this.eventDate(workPackage, 'start');
        const endDate = this.eventDate(workPackage, 'due');

        const exclusiveEnd = moment(endDate).add(1, 'days').format('YYYY-MM-DD');
        const assignee = (workPackage.assignee as HalResource).href as string;

        return {
          id: `${workPackage.href as string}-${assignee}`,
          resourceId: assignee,
          title: workPackage.subject,
          start: startDate,
          end: exclusiveEnd,
          allDay: true,
          className: `__hl_background_type_${workPackage.type.id as string}`,
          workPackage,
        };
      })
      .filter((event) => !!event) as EventInput[];
  }

  private mapToCalendarResources(workPackages:WorkPackageResource[]) {
    const resources:{ id:string, title:string, principal:HalResource|null }[] = [];

    workPackages.forEach((workPackage:WorkPackageResource) => {
      const assignee = workPackage.assignee as HalResource|undefined;
      if (!assignee) {
        return;
      }

      resources.push({
        id: assignee.href as string,
        title: assignee.name,
        principal: assignee,
      });
    });

    return resources;
  }

  private defaultQueryProps(startDate:string, endDate:string) {
    const props = {
      c: ['id'],
      t:
        'id:asc',
      f: [{ n: 'status', o: 'o', v: [] },
        { n: 'datesInterval', o: '<>d', v: [startDate, endDate] }],
      pp: 100,
    };

    return JSON.stringify(props);
  }

  private eventDate(workPackage:WorkPackageResource, type:'start'|'due'):string {
    if (this.schemaCache.of(workPackage).isMilestone) {
      return workPackage.date;
    }
    return workPackage[`${type}Date`] as string;
  }

  private calendarHeight():number {
    let heightElement = jQuery(this.elementRef.nativeElement);

    while (!heightElement.height() && heightElement.parent()) {
      heightElement = heightElement.parent();
    }

    const topOfCalendar = jQuery(this.elementRef.nativeElement).position().top;
    const topOfHeightElement = heightElement.position().top;

    return heightElement.height()! - (topOfCalendar - topOfHeightElement);
  }
}
