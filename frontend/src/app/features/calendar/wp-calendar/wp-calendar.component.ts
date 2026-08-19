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

import { ChangeDetectionStrategy, Component, ElementRef, Input, OnInit, ViewChild, ViewEncapsulation, inject } from '@angular/core';
import {
  CalendarOptions,
  DateSelectArg,
  EventClickArg,
  EventDropArg,
  EventInput,
  ToolbarInput,
} from '@fullcalendar/core';
import { FullCalendarComponent } from '@fullcalendar/angular';
import dayGridPlugin from '@fullcalendar/daygrid';
import moment from 'moment';
import { Subject } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { DomSanitizer } from '@angular/platform-browser';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import interactionPlugin, { EventDragStartArg, EventDragStopArg, EventResizeDoneArg } from '@fullcalendar/interaction';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  CalendarViewEvent,
  OpWorkPackagesCalendarService,
} from 'core-app/features/calendar/op-work-packages-calendar.service';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { EffectCallback, registerEffectCallbacks } from 'core-app/core/state/effects/effect-handler.decorator';
import { calendarRefreshRequest } from 'core-app/features/calendar/calendar.actions';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import {
  addBackgroundEvents,
  removeBackgroundEvents,
} from 'core-app/features/team-planner/team-planner/planner/background-events';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import allLocales from '@fullcalendar/core/locales-all';
import { MeetingResource } from 'core-app/features/hal/resources/meeting-resource';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

@Component({
  templateUrl: './wp-calendar.template.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  styleUrls: ['./wp-calendar.sass'],
  selector: 'op-wp-calendar',
  providers: [
    OpWorkPackagesCalendarService,
    OpCalendarService,
  ],
  standalone: false,
})
export class WorkPackagesCalendarComponent extends UntilDestroyedMixin implements OnInit {
  readonly actions$ = inject(ActionsService);
  readonly states = inject(States);
  readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  readonly wpListService = inject(WorkPackagesListService);
  readonly querySpace = inject(IsolatedQuerySpace);
  readonly schemaCache = inject(SchemaCacheService);
  private element = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly i18n = inject(I18nService);
  readonly toastService = inject(ToastService);
  private sanitizer = inject(DomSanitizer);
  private I18n = inject(I18nService);
  private configuration = inject(ConfigurationService);
  readonly calendar = inject(OpCalendarService);
  readonly workPackagesCalendar = inject(OpWorkPackagesCalendarService);
  readonly currentProject = inject(CurrentProjectService);
  readonly halEditing = inject(HalResourceEditingService);
  readonly halNotification = inject(HalResourceNotificationService);
  readonly weekdayService = inject(WeekdayService);
  readonly dayService = inject(DayResourceService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly pathHelper = inject(PathHelperService);
  readonly timezoneService = inject(TimezoneService);

  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @ViewChild('ucCalendar', { read: ElementRef })
  set ucCalendarElement(v:ElementRef<HTMLElement>|undefined) {
    this.calendar.resizeObserver(v);
  }

  @Input() static = false;

  @Input() showMeetings = false;

  calendarOptions$ = new Subject<CalendarOptions>();

  private alreadyLoaded = false;

  text = {
    cannot_drag_to_non_working_day: this.I18n.t('js.team_planner.cannot_drag_to_non_working_day'),
    today: this.I18n.t('js.team_planner.today'),
  };

  ngOnInit():void {
    registerEffectCallbacks(this, this.untilDestroyed());

    this.wpTableFilters.hidden.push(
      'project',
    );
    this.calendar.resize$
      .pipe(
        this.untilDestroyed(),
        debounceTime(50),
      )
      .subscribe(() => {
        this.ucCalendar.getApi().updateSize();
      });

    // Clear any old subscribers
    this.querySpace.stopAllSubscriptions.next();

    this.initializeCalendar();
  }

  public async calendarEventsFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
  ):Promise<void> {
    await this.workPackagesCalendar.updateTimeframe(fetchInfo, this.currentProject.identifier || undefined);

    if (this.alreadyLoaded) {
      this.alreadyLoaded = false;
      const events = this.updateResults(this.querySpace.results.value!);
      successCallback(events);
    } else {
      this
        .workPackagesCalendar
        .currentWorkPackages$
        .subscribe((collection:WorkPackageCollectionResource) => {
          const events = this.updateResults((collection));
          successCallback(events);
        });
    }
  }

  public calendarMeetingsFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
  ):void {
    if (!this.showMeetings) {
      successCallback([]);
      return;
    }

    const startDate = moment(fetchInfo.start).format('YYYY-MM-DD');
    const endDate = moment(fetchInfo.end).format('YYYY-MM-DD');

    const filters = new ApiV3FilterBuilder();
    filters.add('datesInterval', '<>d', [startDate, endDate]);

    if (this.currentProject.id) {
      filters.add('project', '=', [this.currentProject.id]);
    }

    this
      .apiV3Service
      .meetings
      .filtered(filters, { pageSize: '-1' })
      .get()
      .subscribe((meetings) => {
        const events:EventInput[] = meetings.elements.map((meeting:MeetingResource) => {
          const sameProject = this.currentProject.id === meeting.project.id;
          const title:string = sameProject ? meeting.title : `${meeting.project.name}: ${meeting.title}`;
          return {
            title,
            start: this.timezoneService.parseDatetime(meeting.startTime as string).format(),
            end: this.timezoneService.parseDatetime(meeting.endTime as string).format(),
            editable: false,
            durationEditable: false,
            allDay: false,
            className: 'fc-event-clickable op-wp-calendar--meeting-resource',
            meeting,
          };
        });

        successCallback(events);
      });
  }

  // eslint-disable-next-line @angular-eslint/use-lifecycle-interface
  ngOnDestroy():void {
    super.ngOnDestroy();
    this.calendar.resizeObs?.disconnect();
  }

  private initializeCalendar() {
    const additionalOptions:Record<string, unknown> = {
      locales: allLocales,
      locale: this.I18n.locale,
      height: '100%',
      headerToolbar: this.buildHeader(),
      eventSources: [
        {
          id: 'work_packages',
          events: this.calendarEventsFunction.bind(this) as unknown,
        },
        {
          id: 'meetings',
          events: this.calendarMeetingsFunction.bind(this) as unknown,
          eventDisplay: 'block',
        },
        {
          events: [],
          id: 'background',
          color: 'red',
          background: 'red',
          textColor: 'white',
          display: 'background',
          editable: false,
        },
      ],
      plugins: [
        dayGridPlugin,
        interactionPlugin,
      ],
      // DnD configuration
      selectable: true,
      select: this.handleDateClicked.bind(this),
      eventResizableFromStart: true,
      editable: true,
      displayEventTime: true,
      displayEventEnd: true,
      eventTimeFormat: {
        hour: 'numeric',
        minute: '2-digit',
        meridiem: 'short',
      },
      eventDidMount: (evt:CalendarViewEvent) => {
        const { el, event } = evt;
        if (event.source?.id !== 'work_packages') {
          return;
        }
        const workPackage = event.extendedProps.workPackage as WorkPackageResource;
        el.dataset.workPackageId = workPackage.id!;
      },
      eventResize: (resizeInfo:EventResizeDoneArg) => {
        const due = moment(resizeInfo.event.endStr).subtract(1, 'day').toDate();
        const start = moment(resizeInfo.event.startStr).toDate();
        const wp = resizeInfo.event.extendedProps.workPackage as WorkPackageResource;
        if (!wp.ignoreNonWorkingDays && (this.weekdayService.isNonWorkingDay(start) || this.weekdayService.isNonWorkingDay(due)
          || this.workPackagesCalendar.isNonWorkingDay(start) || this.workPackagesCalendar.isNonWorkingDay(due))) {
          this.toastService.addError(this.text.cannot_drag_to_non_working_day);
          resizeInfo?.revert();
          return;
        }
        void this.updateEvent(resizeInfo, false);
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
      eventResizeStart: (resizeInfo:EventResizeDoneArg) => {
        const wp = resizeInfo.event.extendedProps.workPackage as WorkPackageResource;
        if (!wp.ignoreNonWorkingDays) {
          this.addBackgroundEventsForNonWorkingDays();
        }
      },
      eventResizeStop: () => removeBackgroundEvents(this.ucCalendar.getApi()),
      eventDragStart: (dragInfo:EventDragStartArg) => {
        const wp = dragInfo.event.extendedProps.workPackage as WorkPackageResource;
        if (!wp.ignoreNonWorkingDays) {
          this.addBackgroundEventsForNonWorkingDays();
        }
      },
      eventDragStop: (dragInfo:EventDragStopArg) => {
        const { el } = dragInfo;
        el.style.removeProperty('pointer-events');
        removeBackgroundEvents(this.ucCalendar.getApi());
      },
      eventClick: (evt:EventClickArg) => {
        if (evt.event.extendedProps.meeting) {
          const meeting = evt.event.extendedProps.meeting as MeetingResource;
          window.location.href = this.pathHelper.meetingPath(meeting.id!);
        }

        if (evt.event.extendedProps.workPackage) {
          const wp = evt.event.extendedProps.workPackage as WorkPackageResource;
          // Currently the calendar widget is shown on multiple pages,
          // but only the calendar module itself is a partitioned query space which can deal with a split screen request
          if (window.location.pathname.includes('/calendars/')) {
            this.workPackagesCalendar.openSplitView(wp.id!);
          } else {
            window.location.href = this.pathHelper.workPackagePath(wp.displayId);
          }
        }
      },
    };

    if (this.static) {
      additionalOptions.initialView = 'dayGridWeek';
    }

    void this.weekdayService.loadWeekdays()
      .toPromise()
      .then(() => {
        this.calendarOptions$.next(
          this.workPackagesCalendar.calendarOptions(additionalOptions),
        );
      });
  }

  public buildHeader():false|ToolbarInput|undefined {
    if (this.static) {
      return false;
    }
    return {
      right: 'dayGridMonth,dayGridWeek',
      center: 'title',
      left: 'prev,next today',
    };
  }

  public openContextMenu(event:MouseEvent):void {
    const eventContainer = (event.target as HTMLElement).closest('.fc-event') as HTMLElement|undefined;
    if (!eventContainer) {
      return;
    }

    const workPackageId = eventContainer.dataset.workPackageId!;
    this.workPackagesCalendar.showEventContextMenu({ workPackageId, event });
  }

  private updateResults(collection:WorkPackageCollectionResource) {
    this.workPackagesCalendar.warnOnTooManyResults(collection, this.static);
    return this.mapToCalendarEvents(collection.elements);
  }

  private mapToCalendarEvents(workPackages:WorkPackageResource[]) {
    return workPackages.map((workPackage:WorkPackageResource) => {
      const startDate = this.workPackagesCalendar.eventDate(workPackage, 'start');
      const endDate = this.workPackagesCalendar.eventDate(workPackage, 'due');

      const exclusiveEnd = endDate && moment(endDate).add(1, 'days').format('YYYY-MM-DD');
      // An event is visible on the calendar only if it has a start date.
      // That's why the end date is used as event start date if the work package
      // does not have a proper start date.
      const visibleStart = startDate || endDate;

      return {
        title: workPackage.subject,
        start: visibleStart,
        editable: this.workPackagesCalendar.dateEditable(workPackage),
        durationEditable: this.workPackagesCalendar.eventDurationEditable(workPackage),
        end: exclusiveEnd,
        allDay: true,
        className: `fc-event-clickable __hl_background_type_${workPackage.type.id ?? ''}`,
        workPackage,
      };
    });
  }

  private async updateEvent(info:EventResizeDoneArg|EventDropArg, dragged:boolean):Promise<void> {
    const changeset = this.workPackagesCalendar.updateDates(info, dragged);

    try {
      const result = await this.halEditing.save(changeset);
      this.halNotification.showSave(result.resource, result.wasNew);
      this.reloadOnRefreshRequest();
    } catch (e) {
      this.halNotification.handleRawError(e, changeset.projectedResource);
      info.revert();
    }
  }

  private handleDateClicked(info:DateSelectArg) {
    const due = moment(info.endStr).subtract(1, 'day').toDate();
    const nonWorkingDays = this.weekdayService.isNonWorkingDay(info.start) || this.weekdayService.isNonWorkingDay(due)
      || this.workPackagesCalendar.isNonWorkingDay(info.start) || this.workPackagesCalendar.isNonWorkingDay(due);

    const defaults = {
      startDate: info.startStr,
      dueDate: this.workPackagesCalendar.getEndDateFromTimestamp(info.endStr),
      ignoreNonWorkingDays: nonWorkingDays,
    };

    if (window.location.pathname.includes('/calendars/')) {
      const extraParams:Record<string, string> = {
        startDate: defaults.startDate,
        dueDate: defaults.dueDate,
        ...(defaults.ignoreNonWorkingDays ? { ignoreNonWorkingDays: 'true' } : {}),
      };
      this.workPackagesCalendar.openSplitCreate(extraParams);
    }
  }

  @EffectCallback(calendarRefreshRequest)
  reloadOnRefreshRequest():void {
    this.ucCalendar.getApi().refetchEvents();
  }

  private addBackgroundEventsForNonWorkingDays() {
    addBackgroundEvents(
      this.ucCalendar.getApi(),
      (date) => this.weekdayService.isNonWorkingDay(date) || this.workPackagesCalendar.isNonWorkingDay(date),
    );
  }
}
