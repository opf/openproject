import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injector,
  OnDestroy,
  OnInit,
  TemplateRef,
  ViewChild,
} from '@angular/core';
import {
  CalendarOptions,
  EventInput,
} from '@fullcalendar/core';
import resourceTimelinePlugin from '@fullcalendar/resource-timeline';
import interactionPlugin, { DateClickArg } from '@fullcalendar/interaction';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { FullCalendarComponent } from '@fullcalendar/angular';
import { EventViewLookupService } from 'core-app/features/team-planner/team-planner/planner/event-view-lookup.service';
import { States } from 'core-app/core/states/states.service';
import { StateService } from '@uirouter/angular';
import { DomSanitizer } from '@angular/platform-browser';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackagesListChecksumService } from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { OpTitleService } from 'core-app/core/html/op-title.service';
import {
  Observable,
  Subject,
} from 'rxjs';
import { take } from 'rxjs/internal/operators/take';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { EventClickArg } from '@fullcalendar/common';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import {
  debounceTime,
  map,
} from 'rxjs/operators';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { ResourceLabelContentArg } from '@fullcalendar/resource-common';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OPWPQuickAddModalComponent } from 'core-app/features/work-packages/components/op-wp-quick-add-modal/op-wp-quick-add-modal.component';
import { WorkPackageFilterValues } from 'core-app/features/work-packages/components/wp-edit-form/work-package-filter-values';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { itemAddedToQuerySpace } from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space.actions';

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

  calendarOptions$ = new Subject<CalendarOptions>();

  projectIdentifier:string|null = null;

  private resizeObserver:ResizeObserver;

  private resizeSubject = new Subject<unknown>();

  text = {
    assignees: this.I18n.t('js.team_planner.label_assignee_plural'),
  };

  constructor(
    private injector:Injector,
    private elementRef:ElementRef,
    private states:States,
    private $state:StateService,
    private sanitizer:DomSanitizer,
    private configuration:ConfigurationService,
    private apiV3Service:APIV3Service,
    private wpTableFilters:WorkPackageViewFiltersService,
    private wpListService:WorkPackagesListService,
    private querySpace:IsolatedQuerySpace,
    private wpListChecksumService:WorkPackagesListChecksumService,
    private schemaCache:SchemaCacheService,
    private currentProject:CurrentProjectService,
    private titleService:OpTitleService,
    private viewLookup:EventViewLookupService,
    private I18n:I18nService,
    private modalService:OpModalService,
    private halEditing:HalResourceEditingService,
    private halNotification:HalResourceNotificationService,
    private actions$:ActionsService,
  ) {
    super();
  }

  ngOnInit():void {
    this.setupWorkPackagesListener();
    this.initializeCalendar();
    this.projectIdentifier = this.currentProject.identifier;

    this.resizeSubject
      .pipe(
        this.untilDestroyed(),
        debounceTime(50),
      )
      .subscribe(() => {
        this.ucCalendar.getApi().updateSize();
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.resizeObserver?.disconnect();
  }

  public calendarResourcesFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):void|PromiseLike<EventInput[]> {
    this
      .currentWorkPackages()
      .toPromise()
      .then((workPackages) => {
        const resources = this.mapToCalendarResources(workPackages);
        successCallback(resources);
      })
      .catch(failureCallback);
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
            interactionPlugin,
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
          resources: this.calendarResourcesFunction.bind(this) as unknown,
          eventClick: this.openSplitView.bind(this) as unknown,
          dateClick: this.handleDateClicked.bind(this) as unknown,
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

  private openSplitView(event:EventClickArg) {
    const workPackage = event.event.extendedProps.workPackage as WorkPackageResource;

    void this.$state.go(
      `${splitViewRoute(this.$state)}.tabs`,
      { workPackageId: workPackage.id, tabIdentifier: 'overview' },
    );
  }

  private setupWorkPackagesListener() {
    this
      .querySpace
      .results
      .values$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => {
        this.renderCurrent();
      });
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
    const resources:{ id:string, title:string, user:HalResource }[] = [];

    workPackages.forEach((workPackage:WorkPackageResource) => {
      const assignee = workPackage.assignee as HalResource|undefined;
      if (!assignee) {
        return;
      }

      resources.push({
        id: assignee.href as string,
        title: assignee.name,
        user: assignee,
      });
    });

    return resources;
  }

  private defaultQueryProps(startDate:string, endDate:string) {
    const props = {
      c: ['id'],
      t:
        'id:asc',
      f: [
        { n: 'assignee', o: '*', v: [] },
        { n: 'status', o: 'o', v: [] },
        { n: 'datesInterval', o: '<>d', v: [startDate, endDate] }
      ],
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

  private handleDateClicked(info:DateClickArg) {
    const modal = this.modalService.show(OPWPQuickAddModalComponent, this.injector);
    void modal
      .closingEvent
      .toPromise()
      .then((instance:OPWPQuickAddModalComponent) => {
        if (instance.selectedWorkPackage) {
          void this.addWorkPackageToCell(instance.selectedWorkPackage, info);
        }
      });
  }

  private async addWorkPackageToCell(workPackage:WorkPackageResource, info:DateClickArg) {
    const changeset = this.halEditing.edit(workPackage);
    const assignee = info.resource?.extendedProps.user as UserResource;

    if (!assignee) {
      console.warn('Resource info is not present in date click: %O', info);
      return;
    }

    // Override the assignee
    changeset.setValue('assignee', assignee);

    // Take over any other filter values
    new WorkPackageFilterValues(
      this.injector,
      this.wpTableFilters.current,
    ).applyDefaultsFromFilters(changeset);

    // Save the changes
    void this
      .halEditing
      .save(changeset)
      .then(() => {
        this.actions$.dispatch(
          itemAddedToQuerySpace({ workPackages: [workPackage.id as string] }),
        );
      })
      .catch((error:ErrorResource|unknown) => {
        this.halNotification.handleRawError(error);
      });
  }
}
