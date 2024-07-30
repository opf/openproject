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
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  Injector,
  OnDestroy,
  OnInit,
  TemplateRef,
  ViewChild,
} from '@angular/core';
import { CalendarOptions, DateSelectArg, EventApi, EventDropArg, EventInput } from '@fullcalendar/core';
import { BehaviorSubject, combineLatest, Subject } from 'rxjs';
import {
  debounceTime,
  distinctUntilChanged,
  filter,
  finalize,
  map,
  mergeMap,
  shareReplay,
  startWith,
  switchMap,
  take,
  withLatestFrom,
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
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { ApiV3ListFilter, ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { MAGIC_PAGE_NUMBER } from 'core-app/core/apiv3/helpers/get-paginated-results';
import { CalendarDragDropService } from 'core-app/features/team-planner/team-planner/calendar-drag-drop.service';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import {
  KeepTabService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import {
  teamPlannerEventAdded,
  teamPlannerEventRemoved,
  teamPlannerPageRefresh,
} from 'core-app/features/team-planner/team-planner/planner/team-planner.actions';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { skeletonEvents, skeletonResources } from './loading-skeleton-data';
import { CapabilitiesResourceService } from 'core-app/core/state/capabilities/capabilities.service';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { OpWorkPackagesCalendarService } from 'core-app/features/calendar/op-work-packages-calendar.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { RawOptionsFromRefiners } from '@fullcalendar/core/internal';
import { ViewOptionRefiners } from '@fullcalendar/common';
import { ResourceApi } from '@fullcalendar/resource';
import { DeviceService } from 'core-app/core/browser/device.service';
import { EffectCallback, registerEffectCallbacks } from 'core-app/core/state/effects/effect-handler.decorator';
import {
  addBackgroundEvents,
  removeBackgroundEvents,
} from 'core-app/features/team-planner/team-planner/planner/background-events';
import * as moment from 'moment-timezone';
import allLocales from '@fullcalendar/core/locales-all';

export type TeamPlannerViewOptionKey = 'resourceTimelineWorkWeek'|'resourceTimelineWeek'|'resourceTimelineTwoWeeks'|'resourceTimelineFourWeeks'|'resourceTimelineEightWeeks';
export type TeamPlannerViewOptions = { [K in TeamPlannerViewOptionKey]:RawOptionsFromRefiners<Required<ViewOptionRefiners>> };

@Component({
  selector: 'op-team-planner',
  templateUrl: './team-planner.component.html',
  styleUrls: ['./team-planner.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TeamPlannerComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @ViewChild('ucCalendar', { read: ElementRef })
  set ucCalendarElement(v:ElementRef|undefined) {
    this.calendar.resizeObserver(v);
  }

  @ViewChild('resourceContent') resourceContent:TemplateRef<unknown>;

  @ViewChild('assigneeAutocompleter') assigneeAutocompleter:TemplateRef<unknown>;

  @ViewChild('removeDropzone', { read: ElementRef }) removeDropzone:ElementRef;

  @ViewChild('addExistingToggle', { read: ElementRef }) addExistingToggle:ElementRef;

  calendarOptions$ = new Subject<CalendarOptions>();

  draggingItem$ = new BehaviorSubject<EventDragStartArg|undefined>(undefined);

  globalDraggingItem$ = combineLatest([
    this.draggingItem$,
    this.calendarDrag.isDragging$,
  ]).pipe(
    map(([draggingItem, externalDrag]) => {
      if (externalDrag !== undefined) {
        return externalDrag;
      }

      if (draggingItem !== undefined) {
        return (draggingItem.event.extendedProps.workPackage as WorkPackageResource).id as string;
      }

      return undefined;
    }),
  );

  dropzoneHovered$ = new BehaviorSubject<boolean>(false);

  dropzoneAllowed$ = this
    .draggingItem$
    .pipe(
      filter((dragging) => !!dragging),
      map((dragging) => {
        const workPackage = (dragging as EventDragStartArg).event.extendedProps.workPackage as WorkPackageResource;
        const dateEditable = this.workPackagesCalendar.dateEditable(workPackage);
        const resourceEditable = this.eventResourceEditable(workPackage);
        return dateEditable && resourceEditable;
      }),
    );

  dropzone$ = combineLatest([
    this.draggingItem$,
    this.dropzoneHovered$,
    this.dropzoneAllowed$,
  ])
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
        const assigneeFilter = queryFilters.find((queryFilter) => queryFilter.id === 'assignee');
        return ((assigneeFilter?.values || []) as HalResource[]).map((p) => p.id);
      }),
    );

  private assigneeCaps$ = this.wpTableFilters
    .live$()
    .pipe(
      this.untilDestroyed(),
      switchMap((queryFilters) => {
        const filters:ApiV3ListFilter[] = [
          ['action', '=', ['work_packages/assigned']],
        ];
        const assigneeFilter = queryFilters.find((queryFilter) => queryFilter.id === 'assignee');
        if (assigneeFilter) {
          const values = (assigneeFilter.values as HalResource[]).map((el:HalResource) => el.id as string);
          filters.push(['principal', '=', values]);
        }

        const projectFilter = queryFilters.find((queryFilter) => queryFilter.id === 'project');
        if (projectFilter) {
          const values = (projectFilter.values as HalResource[]).map((el:HalResource) => `p${el.id as string}`);
          filters.push(['context', '=', values]);
        } else {
          filters.push(['context', '=', [`p${this.currentProject.id as string}`]]);
        }

        return this
          .capabilitiesResourceService
          .fetchCapabilities({ pageSize: MAGIC_PAGE_NUMBER, filters });
      }),
      map((result) => result
        ._embedded
        .elements
        .reduce(
          (list:{ [projectId:string]:string[] }, cap:ICapability) => {
            const project = cap._links.context.href;
            const principal = cap._links.principal.href;
            const cur = list[project] || [];
            return {
              ...list,
              [project]: [...cur, principal],
            };
          },
          {},
        )),
      startWith({} as { [projectId:string]:string[] }),
      shareReplay(1),
    );

  private params$ = this.principalIds$
    .pipe(
      this.untilDestroyed(),
      filter((ids) => ids.length > 0),
      map((ids) => ({
        filters: [['id', '=', ids]],
        pageSize: MAGIC_PAGE_NUMBER,
      }) as ApiV3ListParameters),
    );

  isEmpty$ = combineLatest([
    this.principalIds$,
    this.showAddAssignee$,
  ]).pipe(
    debounceTime(250),
    map(([principals, showAddAssignee]) => {
      this.loadingIndicatorService.table.stop();
      return !principals.length && !showAddAssignee;
    }),
  );

  private loading$:Subject<unknown>|null = null;

  assignees:HalResource[] = [];

  statuses:StatusResource[] = [];

  image = {
    empty_state: imagePath('team-planner/empty-state.svg'),
  };

  text = {
    add_existing: this.I18n.t('js.team_planner.add_existing'),
    add_existing_title: this.I18n.t('js.team_planner.add_existing_title'),
    assignee: this.I18n.t('js.label_assignee'),
    add_assignee: this.I18n.t('js.team_planner.add_assignee'),
    remove_assignee: this.I18n.t('js.team_planner.remove_assignee'),
    noData: this.I18n.t('js.team_planner.no_data'),
    work_week: this.I18n.t('js.team_planner.work_week'),
    two_weeks: this.I18n.t('js.team_planner.two_weeks'),
    one_week: this.I18n.t('js.team_planner.one_week'),
    four_weeks: this.I18n.t('js.team_planner.four_weeks'),
    eight_weeks: this.I18n.t('js.team_planner.eight_weeks'),
    today: this.I18n.t('js.team_planner.today'),
    drag_here_to_remove: this.I18n.t('js.team_planner.drag_here_to_remove'),
    cannot_drag_here: this.I18n.t('js.team_planner.cannot_drag_here'),
    updating: this.I18n.t('js.ajax.updating'),
    successful_update: this.I18n.t('js.notice_successful_update'),
    cannot_drag_to_non_working_day: this.I18n.t('js.team_planner.cannot_drag_to_non_working_day'),
  };

  principals$ = this.principalIds$
    .pipe(
      this.untilDestroyed(),
      mergeMap((ids:string[]) => this.principalsResourceService.lookupMany(ids)),
      debounceTime(50),
      distinctUntilChanged((prev, curr) => prev.length === curr.length && prev.length === 0),
      shareReplay(1),
    );

  isMobile = this.deviceService.isMobile;

  private initialCalendarView = this.workPackagesCalendar.initialView || 'resourceTimelineWorkWeek';

  private viewOptionDefaults = {
    type: 'resourceTimeline',
    slotDuration: { days: 1 },
    resourceAreaColumns: [
      {
        field: 'title',
        headerContent: {
          html: `<span class="spot-link spot-link_inactive"><span aria-label="${this.text.assignee}" class="spot-icon spot-icon_user"></span><span class="hidden-for-mobile">${this.text.assignee}</span></span>`,
        },
      },
    ],
  };

  public viewOptions:TeamPlannerViewOptions = {
    resourceTimelineWorkWeek: {
      ...this.viewOptionDefaults,
      ...{
        duration: { weeks: 1 },
        slotLabelFormat: [
          { weekday: 'long', day: '2-digit' },
        ],
        buttonText: this.text.work_week,
      },
    },
    resourceTimelineWeek: {
      ...this.viewOptionDefaults,
      ...{
        duration: { weeks: 1 },
        slotLabelFormat: [
          { weekday: 'long', day: '2-digit' },
        ],
        buttonText: this.text.one_week,
      },
    },
    resourceTimelineTwoWeeks: {
      ...this.viewOptionDefaults,
      ...{
        buttonText: this.text.two_weeks,
        duration: { weeks: 2 },
        dateIncrement: { weeks: 1 },
        slotLabelFormat: [
          { weekday: 'short', day: '2-digit' },
        ],
      },
    },
    resourceTimelineFourWeeks: {
      ...this.viewOptionDefaults,
      ...{
        buttonText: this.text.four_weeks,
        duration: { weeks: 4 },
        dateIncrement: { weeks: 2 },
        slotLabelFormat: [
          { weekday: 'short', day: '2-digit' },
        ],
      },
    },
    resourceTimelineEightWeeks: {
      ...this.viewOptionDefaults,
      ...{
        buttonText: this.text.eight_weeks,
        duration: { weeks: 8 },
        dateIncrement: { weeks: 4 },
        slotLabelFormat: [
          { weekday: 'short', day: '2-digit' },
        ],
      },
    },
  };

  constructor(
    private $state:StateService,
    private configuration:ConfigurationService,
    private principalsResourceService:PrincipalsResourceService,
    private capabilitiesResourceService:CapabilitiesResourceService,
    private wpTableFilters:WorkPackageViewFiltersService,
    private querySpace:IsolatedQuerySpace,
    private currentProject:CurrentProjectService,
    private I18n:I18nService,
    readonly injector:Injector,
    readonly calendar:OpCalendarService,
    readonly workPackagesCalendar:OpWorkPackagesCalendarService,
    readonly halEditing:HalResourceEditingService,
    readonly halNotification:HalResourceNotificationService,
    readonly schemaCache:SchemaCacheService,
    readonly apiV3Service:ApiV3Service,
    readonly calendarDrag:CalendarDragDropService,
    readonly keepTab:KeepTabService,
    readonly actions$:ActionsService,
    readonly toastService:ToastService,
    readonly loadingIndicatorService:LoadingIndicatorService,
    readonly weekdayService:WeekdayService,
    readonly deviceService:DeviceService,
  ) {
    super();
  }

  ngOnInit():void {
    registerEffectCallbacks(this, this.untilDestroyed());
    this.initializeCalendar();
    this.projectIdentifier = this.currentProject.identifier || undefined;

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
        this.principalsResourceService.requireCollection(params).subscribe();
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

        // This also removes the skeleton resources that are rendered initially
        api.getResources().forEach((resource:ResourceApi) => resource.remove());

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
    void this.weekdayService.loadWeekdays()
      .toPromise()
      .then(() => {
        this.calendarOptions$.next(
          this.workPackagesCalendar.calendarOptions({
            locales: allLocales,
            locale: this.I18n.locale,
            schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
            selectable: true,
            plugins: [resourceTimelinePlugin, interactionPlugin],
            titleFormat: { year: 'numeric', month: 'long', day: 'numeric' },
            initialView: this.initialCalendarView,
            headerToolbar: {
              left: '',
              center: 'title',
              right: 'prev,next today',
            },
            views: _.merge(
              {},
              this.viewOptions,
              {
                resourceTimelineWorkWeek: {
                  hiddenDays: this.weekdayService.nonWorkingDays.map((weekday) => weekday.day % 7), // The OP days are 1 based but this needs to be 0 based.
                },
              },
            ),
            // Ensure we show the skeleton from the beginning
            progressiveEventRendering: true,
            eventSources: [
              {
                id: 'skeleton',
                events: skeletonEvents,
                editable: false,
              },
              {
                id: 'work_packages',
                events: this.calendarEventsFunction.bind(this) as unknown,
              },
              {
                events: [],
                id: 'background',
                color: 'red',
                textColor: 'white',
                display: 'background',
                editable: false,
              },
            ],
            resources: skeletonResources,
            resourceAreaWidth: this.isMobile ? '60px' : '180px',
            resourceOrder: 'title',
            select: this.handleDateClicked.bind(this) as unknown,
            // DnD configuration
            editable: true,
            droppable: true,
            eventResize: (resizeInfo:EventResizeDoneArg) => {
              const due = moment(resizeInfo.event.endStr).subtract(1, 'day').toDate();
              const start = moment(resizeInfo.event.startStr).toDate();
              const wp = resizeInfo.event.extendedProps.workPackage as WorkPackageResource;
              if (!wp.ignoreNonWorkingDays && (this.weekdayService.isNonWorkingDay(start) || this.weekdayService.isNonWorkingDay(due)
              || this.workPackagesCalendar.isNonWorkingDay(start)|| this.workPackagesCalendar.isNonWorkingDay(due))) {
                this.toastService.addError(this.text.cannot_drag_to_non_working_day);
                resizeInfo?.revert();
                return;
              }
              void this.updateEvent(resizeInfo, false);
            },
            eventResizeStart: (resizeInfo:EventResizeDoneArg) => {
              const wp = resizeInfo.event.extendedProps.workPackage as WorkPackageResource;
              if (!wp.ignoreNonWorkingDays) {
                this.addBackgroundEventsForNonWorkingDays();
              }
            },
            eventResizeStop: () => removeBackgroundEvents(this.ucCalendar.getApi()),
            eventDragStart: (dragInfo:EventDragStartArg) => {
              if (dragInfo.event.source?.id === 'skeleton') {
                return;
              }

              const { el } = dragInfo;
              el.style.pointerEvents = 'none';
              this.draggingItem$.next(dragInfo);
              this.addBackgroundEvents(dragInfo.event);
            },
            eventDragStop: (dragInfo:EventDragStopArg) => {
              const { el } = dragInfo;
              el.style.removeProperty('pointer-events');
              this.draggingItem$.next(undefined);
              removeBackgroundEvents(this.ucCalendar.getApi());
            },
            eventDrop: (dropInfo:EventDropArg) => {
              const start = moment(dropInfo.event.startStr).toDate();
              const wp = dropInfo.event.extendedProps.workPackage as WorkPackageResource;
              if (!wp.ignoreNonWorkingDays && (this.weekdayService.isNonWorkingDay(start) || this.workPackagesCalendar.isNonWorkingDay(start))) {
                this.toastService.addError(this.text.cannot_drag_to_non_working_day);
                dropInfo?.revert();
                return;
              }
              void this.updateEvent(dropInfo, true);
            },
            eventReceive: async (dropInfo:EventReceiveArg) => {
              const start = moment(dropInfo.event.startStr).toDate();
              const wp = dropInfo.event.extendedProps.workPackage as WorkPackageResource;
              if (!wp.ignoreNonWorkingDays && (this.weekdayService.isNonWorkingDay(start) || this.workPackagesCalendar.isNonWorkingDay(start))) {
                this.toastService.addError(this.text.cannot_drag_to_non_working_day);
                dropInfo?.revert();
                return;
              }
              await this.updateEvent(dropInfo, true);
              this.actions$.dispatch(teamPlannerEventAdded({ workPackage: wp.id as string }));
            },
          } as CalendarOptions),
        );
      });
  }

  public async calendarEventsFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):Promise<void> {
    await this.workPackagesCalendar.updateTimeframe(fetchInfo, this.projectIdentifier);

    this
      .workPackagesCalendar
      .currentWorkPackages$
      .pipe(
        withLatestFrom(this.assigneeCaps$),
        take(1),
        finalize(() => this.clearLoading()),
      )
      .subscribe(
        ([workPackages, projectAssignables]) => {
          const events = this.mapToCalendarEvents(workPackages.elements, projectAssignables);

          this.workPackagesCalendar.warnOnTooManyResults(workPackages);

          this.removeExternalEvents();

          successCallback(events);

          this.ucCalendar.getApi().render();
        },
        failureCallback,
      );
  }

  public switchView(key:TeamPlannerViewOptionKey):void {
    this.ucCalendar.getApi().changeView(key);
  }

  public get currentViewTitle():string {
    return this.viewOptions[((this.ucCalendar && this.ucCalendar.getApi().view.type) || this.initialCalendarView) as TeamPlannerViewOptionKey].buttonText as string;
  }

  /**
   * Clear loading and show successful toast if we were reloading the page
   * @private
   */
  private clearLoading():void {
    const prevLoading = this.loading$;
    if (!prevLoading) {
      return;
    }

    this.loading$ = null;
    setTimeout(() => {
      prevLoading.complete();
      this.toastService.addSuccess(this.text.successful_update);
    }, 500);
  }

  isDraggedEvent(id:string):boolean {
    const dragging = this.draggingItem$.getValue();
    return !!dragging && (dragging.event.extendedProps?.workPackage as undefined|WorkPackageResource)?.href === id;
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

  isWpEndDateInCurrentView(workPackage:WorkPackageResource):boolean {
    const { dueDate } = workPackage;

    if (!dueDate) {
      return !!workPackage.date;
    }

    const viewEndDate = this.ucCalendar.getApi().view.currentEnd.setHours(0, 0, 0, 0);
    const dateToCheck = new Date(dueDate).setHours(0, 0, 0, 0);

    return dateToCheck < viewEndDate;
  }

  isWpStartDateInCurrentView(workPackage:WorkPackageResource):boolean {
    const { startDate } = workPackage;

    if (!startDate) {
      return !!workPackage.date;
    }

    const viewStartDate = this.ucCalendar.getApi().view.currentStart.setHours(0, 0, 0, 0);
    const dateToCheck = new Date(startDate).setHours(0, 0, 0, 0);

    return dateToCheck >= viewStartDate;
  }

  showDisabledText(workPackage:WorkPackageResource):{ text:string, orientation:'left'|'right' } {
    const dueDate = new Date(workPackage.dueDate).setHours(0, 0, 0, 0);
    const firstCalendarDay = this.ucCalendar.getApi().view.currentStart.setHours(0, 0, 0, 0);
    return {
      text: this.calendarDrag.workPackageDisabledExplanation(workPackage),
      orientation: dueDate === firstCalendarDay ? 'right' : 'left',
    };
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

  private mapToCalendarEvents(
    workPackages:WorkPackageResource[],
    projectAssignables:{ [projectId:string]:string[] },
  ):EventInput[] {
    return workPackages
      .map((workPackage:WorkPackageResource):EventInput|undefined => {
        if (!workPackage.assignee) {
          return undefined;
        }

        const assignee = this.wpAssignee(workPackage);
        const durationEditable = this.workPackagesCalendar.eventDurationEditable(workPackage);
        const resourceEditable = this.eventResourceEditable(workPackage);

        return {
          id: `${workPackage.href as string}-${assignee}`,
          resourceId: assignee,
          editable: durationEditable || resourceEditable,
          durationEditable,
          resourceEditable,
          constraint: this.eventConstraints(workPackage, projectAssignables),
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
    const due = moment(info.endStr).subtract(1, 'day').toDate();
    const nonWorkingDays = this.weekdayService.isNonWorkingDay(info.start) || this.weekdayService.isNonWorkingDay(due);

    this.openNewSplitCreate(
      info.startStr,
      // end date is exclusive
      this.workPackagesCalendar.getEndDateFromTimestamp(info.endStr),
      info.resource?.id || '',
      nonWorkingDays,
    );
  }

  // Allow triggering the select from a event, as
  // this is otherwise not testable from selenium
  @HostListener(
    'document:teamPlannerSelectDate',
    ['$event.detail.start', '$event.detail.end', '$event.detail.assignee'],
  )
  openNewSplitCreate(start:string, end:string, resourceHref:string, nonWorkingDays:boolean):void {
    const defaults = {
      startDate: start,
      dueDate: end,
      _links: {
        assignee: {
          href: resourceHref,
        },
      },
      ignoreNonWorkingDays: nonWorkingDays,
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

  shouldShowAsGhost(id:string, globalDraggingId:string|undefined):boolean {
    if (globalDraggingId === undefined) {
      return false;
    }

    // Everything else except the currently dragged element should be shown as ghost.
    return id !== globalDraggingId;
  }

  private async updateEvent(info:EventResizeDoneArg|EventDropArg|EventReceiveArg, dragged:boolean):Promise<void> {
    const changeset = this.workPackagesCalendar.updateDates(info, dragged);
    const resource = info.event.getResources()[0];
    if (resource) {
      changeset.setValue('assignee', { href: resource.id });
    }

    this.calendarDrag.handleDrop(changeset.projectedResource);
    await this.saveChangeset(changeset, info);
  }

  private async saveChangeset(changeset:ResourceChangeset<WorkPackageResource>, info?:EventResizeDoneArg|EventDropArg|EventReceiveArg) {
    try {
      this.loading$ = new Subject<unknown>();
      this.toastService.addLoading(this.loading$);
      await this.halEditing.save(changeset);
    } catch (e:unknown) {
      this.loading$?.complete();
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
  private eventConstraints(
    wp:WorkPackageResource,
    projectAssignables:{ [projectId:string]:string[] },
  ):{ [key:string]:string|string[] } {
    const constraints:{ [key:string]:string|string[] } = {};

    if (!this.workPackagesCalendar.eventDurationEditable(wp) && !wp.date) {
      constraints.start = this.wpStartDate(wp);
      constraints.end = this.wpEndDate(wp);
    }

    if (!this.eventResourceEditable(wp)) {
      constraints.resourceIds = [this.wpAssignee(wp)];
      return constraints;
    }

    const assignables = projectAssignables[(wp.project as HalResource).href as string];
    if (assignables) {
      constraints.resourceIds = [...assignables];
    }

    return constraints;
  }

  private wpStartDate(wp:WorkPackageResource):string {
    return this.workPackagesCalendar.eventDate(wp, 'start');
  }

  private wpEndDate(wp:WorkPackageResource):string {
    const endDate = this.workPackagesCalendar.eventDate(wp, 'due');
    return moment(endDate).add(1, 'days').format('YYYY-MM-DD');
  }

  private wpAssignee(wp:WorkPackageResource):string {
    return (wp.assignee as HalResource).href as string;
  }

  private toggleAddExistingPane():void {
    this.showAddExistingPane.next(!this.showAddExistingPane.getValue());
    (this.addExistingToggle.nativeElement as HTMLElement).blur();
  }

  private removeExternalEvents():void {
    this
      .ucCalendar
      .getApi()
      .getEvents()
      .forEach((evt) => {
        if (evt.id.includes('external')) {
          evt.remove();
        }
      });
  }

  private addBackgroundEvents(event:EventApi) {
    const wp = event.extendedProps.workPackage as WorkPackageResource;

    this
      .assigneeCaps$
      .pipe(
        filter((el) => Object.keys(el).length > 0),
        take(1),
        map((projectAssignables) => projectAssignables[(wp.project as HalResource).href as string]),
        withLatestFrom(this.principals$),
      )
      .subscribe(([assignable, principals]) => {
        const api = this.ucCalendar.getApi();
        if (!wp.ignoreNonWorkingDays) {
          this.addBackgroundEventsForNonWorkingDays();
        }
        const eventBase = {
          start: moment().subtract('1', 'month').toDate(),
          end: moment().add('1', 'month').toDate(),
        };

        principals.forEach((principal) => {
          const resourceId = principal._links.self.href;

          if (!assignable || !assignable.includes(resourceId)) {
            api.addEvent({ ...eventBase, resourceId }, 'background');
          }
        });
      });
  }

  private addBackgroundEventsForNonWorkingDays() {
    addBackgroundEvents(
      this.ucCalendar.getApi(),
      (date) => this.weekdayService.isNonWorkingDay(date)|| this.workPackagesCalendar.isNonWorkingDay(date),
    );
  }

  @EffectCallback(teamPlannerPageRefresh)
  reloadOnEventAdded(action:ReturnType<typeof teamPlannerPageRefresh>):void {
    if (action.showLoading) {
      this.loading$ = new Subject<unknown>();
      this.toastService.addLoading(this.loading$);
    }

    this.ucCalendar.getApi().refetchEvents();
  }
}
