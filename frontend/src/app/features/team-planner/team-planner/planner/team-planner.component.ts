import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  OnDestroy,
  OnInit,
  TemplateRef,
  ViewChild,
} from '@angular/core';
import {
  CalendarOptions,
  DateSelectArg,
  EventContentArg,
  EventDropArg,
  EventInput,
} from '@fullcalendar/core';
import {
  BehaviorSubject,
  combineLatest,
  Subject,
} from 'rxjs';
import {
  debounceTime,
  distinctUntilChanged,
  filter,
  map,
  mergeMap,
  take,
} from 'rxjs/operators';
import { StateService } from '@uirouter/angular';
import resourceTimelinePlugin from '@fullcalendar/resource-timeline';
import interactionPlugin, {
  EventDragStartArg,
  EventDragStopArg,
  EventReceiveArg,
  EventResizeDoneArg,
} from '@fullcalendar/interaction';
import { FullCalendarComponent } from '@fullcalendar/angular';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { EventViewLookupService } from 'core-app/features/team-planner/team-planner/planner/event-view-lookup.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ResourceLabelContentArg } from '@fullcalendar/resource-common';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CalendarDragDropService } from 'core-app/features/team-planner/team-planner/calendar-drag-drop.service';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { teamPlannerEventRemoved } from 'core-app/features/team-planner/team-planner/planner/team-planner.actions';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';

@Component({
  selector: 'op-team-planner',
  templateUrl: './team-planner.component.html',
  styleUrls: ['./team-planner.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    EventViewLookupService,
    OpCalendarService,
  ],
})
export class TeamPlannerComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @ViewChild('ucCalendar', { read: ElementRef })
  set ucCalendarElement(v:ElementRef|undefined) {
    this.calendar.resizeObserver(v);
  }

  @ViewChild('eventContent') eventContent:TemplateRef<unknown>;

  @ViewChild('resourceContent') resourceContent:TemplateRef<unknown>;

  @ViewChild('assigneeAutocompleter') assigneeAutocompleter:TemplateRef<unknown>;

  @ViewChild('removeDropzone', { read: ElementRef }) removeDropzone:ElementRef;

  @ViewChild('addExistingToggle', { read: ElementRef }) addExistingToggle:ElementRef;

  calendarOptions$ = new Subject<CalendarOptions>();

  draggingItem$ = new BehaviorSubject<EventDragStartArg|undefined>(undefined);

  dropzoneHovered$ = new BehaviorSubject<boolean>(false);

  dropzoneAllowed$ = this
    .draggingItem$
    .pipe(
      filter((dragging) => !!dragging),
      map((dragging) => {
        const workPackage = (dragging as EventDragStartArg).event.extendedProps.workPackage as WorkPackageResource;
        const durationEditable = this.calendar.eventDurationEditable(workPackage);
        const resourceEditable = this.eventResourceEditable(workPackage);
        return durationEditable && resourceEditable;
      }),
    );

  dropzone$ = combineLatest([this.draggingItem$, this.dropzoneHovered$, this.dropzoneAllowed$])
    .pipe(
      map(([dragging, isHovering, canDrop]) => ({ dragging, isHovering, canDrop })),
    );

  projectIdentifier:string|undefined = undefined;

  showAddExistingPane = new BehaviorSubject<boolean>(false);

  showAddAssignee$ = new BehaviorSubject<boolean>(false);

  private principalIds$ = this.wpTableFilters
    .live$()
    .pipe(
      this.untilDestroyed(),
      map((queryFilters) => {
        const assigneeFilter = queryFilters.find((queryFilter) => queryFilter._type === 'AssigneeQueryFilter');
        return ((assigneeFilter?.values || []) as HalResource[]).map((p) => p.id);
      }),
    );

  private params$ = this.principalIds$
    .pipe(
      this.untilDestroyed(),
      filter((ids) => ids.length > 0),
      map((ids) => ({
        filters: [['id', '=', ids]],
      }) as ApiV3ListParameters),
    );

  isEmpty$ = combineLatest([
    this.principalIds$,
    this.showAddAssignee$,
  ]).pipe(
    map(([principals, showAddAssignee]) => !principals.length && !showAddAssignee),
  );

  assignees:HalResource[] = [];

  statuses:StatusResource[] = [];

  image = {
    empty_state: imagePath('team-planner/empty-state.svg'),
  };

  text = {
    add_existing: this.I18n.t('js.team_planner.add_existing'),
    assignees: this.I18n.t('js.team_planner.label_assignee_plural'),
    add_assignee: this.I18n.t('js.team_planner.add_assignee'),
    remove_assignee: this.I18n.t('js.team_planner.remove_assignee'),
    noData: this.I18n.t('js.team_planner.no_data'),
    two_weeks: this.I18n.t('js.team_planner.two_weeks'),
    one_week: this.I18n.t('js.team_planner.one_week'),
    today: this.I18n.t('js.team_planner.today'),
    drag_here_to_remove: this.I18n.t('js.team_planner.drag_here_to_remove'),
    cannot_drag_here: this.I18n.t('js.team_planner.cannot_drag_here'),
  };

  principals$ = this.principalIds$
    .pipe(
      this.untilDestroyed(),
      mergeMap((ids:string[]) => this.principalsResourceService.query.byIds(ids)),
      debounceTime(50),
      distinctUntilChanged((prev, curr) => prev.length === curr.length && prev.length === 0),
    );

  constructor(
    private $state:StateService,
    private configuration:ConfigurationService,
    private principalsResourceService:PrincipalsResourceService,
    private wpTableFilters:WorkPackageViewFiltersService,
    private querySpace:IsolatedQuerySpace,
    private currentProject:CurrentProjectService,
    private viewLookup:EventViewLookupService,
    private I18n:I18nService,
    readonly calendar:OpCalendarService,
    readonly halEditing:HalResourceEditingService,
    readonly halNotification:HalResourceNotificationService,
    readonly schemaCache:SchemaCacheService,
    readonly apiV3Service:ApiV3Service,
    readonly calendarDrag:CalendarDragDropService,
    readonly keepTab:KeepTabService,
    readonly actions$:ActionsService,
  ) {
    super();
  }

  ngOnInit():void {
    this.initializeCalendar();
    this.projectIdentifier = this.currentProject.identifier || undefined;

    this
      .querySpace
      .results
      .values$()
      .pipe(this.untilDestroyed())
      .subscribe(() => {
        this.ucCalendar.getApi().refetchEvents();
      });

    this.calendar.resize$
      .pipe(
        this.untilDestroyed(),
        debounceTime(50),
      )
      .subscribe(() => {
        this.ucCalendar.getApi().updateSize();
      });

    this.params$
      .pipe(this.untilDestroyed())
      .subscribe((params) => {
        this.principalsResourceService.fetchPrincipals(params).subscribe();
      });

    combineLatest([
      this.principals$,
      this.showAddAssignee$,
    ])
      .pipe(
        this.untilDestroyed(),
        debounceTime(0),
      )
      .subscribe(([principals, showAddAssignee]) => {
        const api = this.ucCalendar.getApi();

        api.getResources().forEach((resource) => resource.remove());

        principals.forEach((principal) => {
          const id = principal._links.self.href;
          api.addResource({
            principal,
            id,
            title: principal.name,
          });
        });

        if (showAddAssignee) {
          api.addResource({
            principal: null,
            id: 'NEW',
            title: '',
          });
        }
      });

    // This needs to be done after all the subscribers are set up
    this.showAddAssignee$.next(false);

    this
      .apiV3Service
      .statuses
      .get()
      .pipe(
        take(1),
      )
      .subscribe((collection) => {
        this.statuses = collection.elements;
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.calendar.resizeObs?.disconnect();
  }

  private initializeCalendar() {
    void this.configuration.initialized
      .then(() => {
        this.calendarOptions$.next(
          this.calendar.calendarOptions({
            schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
            selectable: true,
            plugins: [
              resourceTimelinePlugin,
              interactionPlugin,
            ],
            titleFormat: {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            },
            buttonText: {
              today: this.text.today,
            },
            initialView: this.calendar.initialView || 'resourceTimelineWeek',
            headerToolbar: {
              left: '',
              center: 'title',
              right: 'prev,next today resourceTimelineWeek,resourceTimelineTwoWeeks',
            },
            views: {
              resourceTimelineWeek: {
                type: 'resourceTimeline',
                buttonText: this.text.one_week,
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
              resourceTimelineTwoWeeks: {
                type: 'resourceTimeline',
                buttonText: this.text.two_weeks,
                slotDuration: { days: 1 },
                duration: { weeks: 2 },
                dateIncrement: { weeks: 1 },
                slotLabelFormat: [
                  {
                    weekday: 'short',
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
            resourceAreaWidth: '180px',
            select: this.handleDateClicked.bind(this) as unknown,
            resourceLabelContent: (data:ResourceLabelContentArg) => this.renderTemplate(this.resourceContent, data.resource.id, data),
            resourceLabelWillUnmount: (data:ResourceLabelContentArg) => this.unrenderTemplate(data.resource.id),
            // DnD configuration
            editable: true,
            droppable: true,
            eventResize: (resizeInfo:EventResizeDoneArg) => this.updateEvent(resizeInfo),
            eventDragStart: (dragInfo:EventDragStartArg) => {
              const { el } = dragInfo;
              el.style.pointerEvents = 'none';
              this.draggingItem$.next(dragInfo);
            },
            eventDragStop: (dragInfo:EventDragStopArg) => {
              const { el } = dragInfo;
              el.style.removeProperty('pointer-events');
              this.draggingItem$.next(undefined);
            },
            eventDrop: (dropInfo:EventDropArg) => this.updateEvent(dropInfo),
            eventReceive: (dropInfo:EventReceiveArg) => this.updateEvent(dropInfo),
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            eventContent: (data:EventContentArg) => this.renderTemplate(this.eventContent, this.eventId(data), data),
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            eventWillUnmount: (data:EventContentArg) => this.unrenderTemplate(this.eventId(data)),
          } as CalendarOptions),
        );
      });
  }

  public calendarEventsFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):void|PromiseLike<EventInput[]> {
    this
      .calendar
      .currentWorkPackages$
      .toPromise()
      .then((workPackages:WorkPackageCollectionResource) => {
        const events = this.mapToCalendarEvents(workPackages.elements);

        this.viewLookup.destroyDetached();

        successCallback(events);
      })
      .catch(failureCallback);

    void this.calendar.updateTimeframe(fetchInfo, this.projectIdentifier);
  }

  renderTemplate(template:TemplateRef<unknown>, id:string, data:ResourceLabelContentArg|EventContentArg):{ domNodes:unknown[] } {
    if (this.isDragggedEvent(id)) {
      this.viewLookup.markForDestruction(id);
    }

    const ref = this.viewLookup.getView(template, id, data);
    return { domNodes: ref.rootNodes };
  }

  unrenderTemplate(id:string):void {
    this.viewLookup.markForDestruction(id);
  }

  isDragggedEvent(id:string):boolean {
    const dragging = this.draggingItem$.getValue();
    return !!dragging && (dragging.event.extendedProps.workPackage as WorkPackageResource).href === id;
  }

  eventId(data:EventContentArg):string {
    return `${data.event.id},dragging=${data.isDragging.toString()}`;
  }

  public showAssigneeAddRow():void {
    this.showAddAssignee$.next(true);
    this.ucCalendar.getApi().refetchEvents();
  }

  public addAssignee(principal:HalResource):void {
    this.showAddAssignee$.next(false);

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

  public removeAssignee(href:string):void {
    const numberOfAssignees = this.wpTableFilters.find('assignee')?.values?.length;
    if (numberOfAssignees && numberOfAssignees <= 1) {
      this.wpTableFilters.remove('assignee');
    } else {
      this.wpTableFilters.modify('assignee', (assigneeFilter:QueryFilterInstanceResource) => {
        // eslint-disable-next-line no-param-reassign
        assigneeFilter.values = (assigneeFilter.values as HalResource[])
          .filter((filterValue) => filterValue.href !== href);
      });
    }
  }

  isWpDateInCurrentView(workPackage:WorkPackageResource, date:'start'|'end'):boolean {
    if (workPackage.startDate && workPackage.dueDate) {
      let dateToCheck;

      const currentStartDate = this.ucCalendar.getApi().view.currentStart;
      const currentEndDate = this.ucCalendar.getApi().view.currentEnd;

      if (date === 'start') {
        dateToCheck = new Date(workPackage.startDate);
      } else {
        dateToCheck = new Date(workPackage.dueDate);
      }

      const dateCurrentlyVisible = dateToCheck >= currentStartDate && dateToCheck <= currentEndDate;
      return dateCurrentlyVisible;
    }

    return false;
  }

  showDisabledText(workPackage:WorkPackageResource):string {
    return this.calendarDrag.workPackageDisabledExplanation(workPackage);
  }

  isStatusClosed(workPackage:WorkPackageResource):boolean {
    const status = this.statuses.find((el) => el.id === (workPackage.status as StatusResource).id);

    return status ? status.isClosed : false;
  }

  public async removeEvent(item:EventDragStartArg):Promise<void> {
    // Remove item from view
    item.el.remove();
    item.event.remove();

    const workPackage = item.event.extendedProps.workPackage as WorkPackageResource;
    const changeset = this.halEditing.edit(workPackage);
    changeset.setValue('assignee', { href: null });
    changeset.setValue('startDate', null);
    changeset.setValue('dueDate', null);

    await this.saveChangeset(changeset);

    this.actions$.dispatch(teamPlannerEventRemoved({ workPackage: workPackage.id as string }));
  }

  private mapToCalendarEvents(workPackages:WorkPackageResource[]):EventInput[] {
    return workPackages
      .map((workPackage:WorkPackageResource):EventInput|undefined => {
        if (!workPackage.assignee) {
          return undefined;
        }

        const assignee = this.wpAssignee(workPackage);
        const durationEditable = this.calendar.eventDurationEditable(workPackage);
        const resourceEditable = this.eventResourceEditable(workPackage);

        return {
          id: `${workPackage.href as string}-${assignee}`,
          resourceId: assignee,
          editable: durationEditable || resourceEditable,
          durationEditable,
          resourceEditable,
          constraint: this.eventConstaints(workPackage),
          title: workPackage.subject,
          start: this.wpStartDate(workPackage),
          end: this.wpEndDate(workPackage),
          backgroundColor: '#FFFFFF',
          borderColor: '#FFFFFF',
          allDay: true,
          workPackage,
        };
      })
      .filter((event) => !!event) as EventInput[];
  }

  private handleDateClicked(info:DateSelectArg) {
    this.openNewSplitCreate(
      info.startStr,
      // end date is exclusive
      this.calendar.getEndDateFromTimestamp(info.end),
      info.resource?.id || '',
    );
  }

  // Allow triggering the select from a event, as
  // this is otherwise not testable from selenium
  @HostListener(
    'document:teamPlannerSelectDate',
    ['$event.detail.start', '$event.detail.end', '$event.detail.assignee'],
  )
  openNewSplitCreate(start:string, end:string, resourceHref:string):void {
    const defaults = {
      startDate: start,
      dueDate: end,
      _links: {
        assignee: {
          href: resourceHref,
        },
      },
    };

    void this.$state.go(
      splitViewRoute(this.$state, 'new'),
      {
        defaults,
        tabIdentifier: 'overview',
      },
    );
  }

  openStateLink(event:{ workPackageId:string; requestedState:string }):void {
    const params = { workPackageId: event.workPackageId };

    if (event.requestedState === 'split') {
      this.keepTab.goCurrentDetailsState(params);
    } else {
      this.keepTab.goCurrentShowState(params);
    }
  }

  private async updateEvent(info:EventResizeDoneArg|EventDropArg|EventReceiveArg):Promise<void> {
    const changeset = this.calendar.updateDates(info);

    const resource = info.event.getResources()[0];
    if (resource) {
      changeset.setValue('assignee', { href: resource.id });
    }

    this.calendarDrag.handleDrop(changeset.projectedResource);
    await this.saveChangeset(changeset, info);
  }

  private async saveChangeset(changeset:ResourceChangeset<WorkPackageResource>, info?:EventResizeDoneArg|EventDropArg|EventReceiveArg) {
    try {
      const result = await this.halEditing.save(changeset);
      this.halNotification.showSave(result.resource, result.wasNew);
    } catch (e:unknown) {
      this.halNotification.showError((e as HalError).resource, changeset.projectedResource);
      this.calendarDrag.handleDropError(changeset.projectedResource);
      info?.revert();
    }
  }

  private eventResourceEditable(wp:WorkPackageResource):boolean {
    const schema = this.schemaCache.of(wp);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return !!schema.assignee?.writable && schema.isAttributeEditable('assignee');
  }

  // Todo: Evaluate whether we really want to use that from a UI perspective ¯\_(ツ)_/¯
  // When users have the right to change the assignee but cannot change the date (due to hierarchy for example),
  // they are forced to drag the wp to the exact same date in the others assignee row. This might be confusing.
  // Without these constraints however, users can drag the WP everywhere, thinking that they changed the date as well.
  // The WP then moves back to the original date when the calendar re-draws again. Also not optimal..
  private eventConstaints(wp:WorkPackageResource):{ [key:string]:string|string[] } {
    const constraints:{ [key:string]:string|string[] } = {};

    if (!this.calendar.eventDurationEditable(wp)) {
      constraints.start = this.wpStartDate(wp);
      constraints.end = this.wpEndDate(wp);
    }

    if (!this.eventResourceEditable(wp)) {
      constraints.resourceIds = [this.wpAssignee(wp)];
    }

    return constraints;
  }

  private wpStartDate(wp:WorkPackageResource):string {
    return this.calendar.eventDate(wp, 'start');
  }

  private wpEndDate(wp:WorkPackageResource):string {
    const endDate = this.calendar.eventDate(wp, 'due');
    return moment(endDate).add(1, 'days').format('YYYY-MM-DD');
  }

  private wpAssignee(wp:WorkPackageResource):string {
    return (wp.assignee as HalResource).href as string;
  }

  private toggleAddExistingPane():void {
    this.showAddExistingPane.next(!this.showAddExistingPane.getValue());
    (this.addExistingToggle.nativeElement as HTMLElement).blur();
  }
}
