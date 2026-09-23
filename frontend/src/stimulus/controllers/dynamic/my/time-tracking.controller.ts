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

import { ActionEvent, Controller } from '@hotwired/stimulus';
import { Calendar, EventApi, EventContentArg } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';
import momentTimezonePlugin from '@fullcalendar/moment-timezone';
import { toMoment } from '@fullcalendar/moment';
import type { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import type { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import moment from 'moment';
import allLocales from '@fullcalendar/core/locales-all';
import { renderStreamMessage } from '@hotwired/turbo';
import { useMeta } from 'stimulus-use';
import { render } from 'lit-html';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';
import { DialogCloseDetail } from 'core-turbo/dialog-stream-action';
import { displayDuration } from 'core-stimulus/helpers/duration-helpers';
import { renderFooterTotals } from 'core-stimulus/helpers/fullcalendar-footer-helpers';
import { ONGOING_CLASS_NAME, renderTimeEntryCard, type TimeEntryCard, type TimeEntryEvent } from 'core-stimulus/helpers/time-entry-event';

interface AdditionalDialogCloseData {
  spent_on?:string;
}

export default class MyTimeTrackingController extends Controller {
  static services:ServiceKey[] = ['turboRequests', 'pathHelperService'];

  declare turboRequests:TurboRequestsService;
  declare pathHelperService:PathHelperService;
  declare services:Promise<PickedServices<'turboRequests'|'pathHelperService'>>;

  static targets = ['calendar'];

  static values = {
    mode: String,
    viewMode: String,
    timeEntries: Array,
    initialDate: String,
    canCreate: Boolean,
    locale: String,
    canEdit: Boolean,
    allowTimes: Boolean,
    forceTimes: Boolean,
    workingDays: Array,
    startOfWeek: Number,
    timeZone: String,
  };

  static metaNames = ['csrf-token'];

  declare readonly calendarTarget:HTMLElement;
  declare readonly hasCalendarTarget:boolean;
  declare readonly modeValue:string;
  declare readonly timeEntriesValue:TimeEntryEvent[];
  declare readonly initialDateValue:string;
  declare readonly canCreateValue:boolean;
  declare readonly canEditValue:boolean;
  declare readonly allowTimesValue:boolean;
  declare readonly forceTimesValue:boolean;
  declare readonly localeValue:string;
  declare readonly viewModeValue:string;
  declare readonly workingDaysValue:number[];
  declare readonly startOfWeekValue:number;
  declare readonly timeZoneValue:string;
  declare readonly csrfToken:string;

  private calendar:Calendar;
  private DEFAULT_TIMED_EVENT_DURATION = '01:00';
  private boundListener = this.dialogCloseListener.bind(this);

  initialize() {
    useAngularServices(this);
  }

  connect() {
    useMeta(this, { suffix: false });
  }

  servicesConnected() {
    if (this.hasCalendarTarget && this.viewModeValue === 'calendar') {
      this.initializeCalendar();

      // The stimulus controller gets initialized before the content wrapper is fully shown
      // so its height might not be set correctly yet.
      setTimeout(() => this.calendar.updateSize(), 25);
    }

    // handle dialog close event
    document.addEventListener('dialog:close', this.boundListener);
  }

  disconnect():void {
    document.removeEventListener('dialog:close', this.boundListener);

    // Clean up calendar when controller disconnects
    if (this.calendar) {
      this.calendar.destroy();
    }
  }

  initializeCalendar() {
    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [timeGridPlugin, dayGridPlugin, interactionPlugin, momentTimezonePlugin],
      initialView: this.calendarView(),
      locales: allLocales,
      locale: this.localeValue,
      timeZone: this.timeZoneValue,
      events: this.timeEntriesValue,
      headerToolbar: false,
      height: '100%',
      initialDate: this.initialDateValue,
      selectable: this.canCreateValue,
      editable: this.canEditValue,
      eventResizableFromStart: true,
      defaultTimedEventDuration: this.DEFAULT_TIMED_EVENT_DURATION,
      allDayContent: '',
      dayMaxEventRows: 4, // 3 + more link
      eventShortHeight: 60,
      eventMinHeight: 30,
      eventMaxStack: 2,
      nowIndicator: true,
      slotDuration: '00:15:00',
      slotLabelInterval: '01:00',
      businessHours: { daysOfWeek: this.workingDaysValue, startTime: '00:00', endTime: '24:00' },
      hiddenDays: this.hiddenDays(),
      firstDay: this.startOfWeekValue,
      eventClassNames(info) {
        const classes = [
          'calendar-time-entry-event',
          `__hl_type_${info.event.extendedProps.typeId}`,
          '__hl_border_top',
          'ellipsis',
        ];

        if (info.event.extendedProps.ongoing) {
          classes.push(ONGOING_CLASS_NAME);
        }

        return classes;
      },
      eventContent: (info) => {
        const wrapper = document.createElement('div');
        wrapper.classList.add('fc-event-main-frame');

        render(this.createEventContent(info), wrapper);

        return { domNodes: [wrapper] };
      },
      select: (info) => {
        let dialogParams = 'onlyMe=true';

        if (info.allDay) {
          dialogParams = `${dialogParams}&date=${info.startStr}`;
        } else {
          dialogParams = `${dialogParams}&startTime=${info.start.toISOString()}&endTime=${info.end.toISOString()}`;
        }

        void this.turboRequests.request(
          `${this.pathHelperService.timeEntryDialog()}?${dialogParams}`,
          { method: 'GET' },
        );
      },
      eventResize: (info) => {
        // it does not make sense to resize the events without start & end times
        // we cannot only disable resize, because we want to be able to drag the events
        // so we need to revert the event to its original size
        if (info.event.allDay || !info.event.start || !info.event.end) {
          info.revert();
          return;
        }

        const startMoment = toMoment(info.event.start, this.calendar);
        const newEventHours = this.calculateHours(info.event);

        info.event.setExtendedProp('hours', newEventHours);

        this.updateTimeEntry(
          info.event.id,
          startMoment.format('YYYY-MM-DD'),
          info.event.allDay ? null : startMoment.format('HH:mm'),
          newEventHours,
          info.revert,
        );
      },

      eventDragStart: (info) => {
        // When dragging from all day into the calendar set the defaultTimedEventDuration to the hours of the event so
        // that we display it correctly in the calendar. Will be reset in the drop event
        if (info.event.allDay) {
          this.calendar.setOption('defaultTimedEventDuration', moment.duration(info.event.extendedProps.hours as number, 'hours').asMilliseconds());
        }
      },

      eventAllow: (dropInfo, draggedEvent) => {
        if (dropInfo.allDay && this.forceTimesValue) {
          return false;
        }

        if (!dropInfo.allDay && draggedEvent?.allDay && !this.allowTimesValue) {
          return false;
        }

        if (draggedEvent?.extendedProps.ongoing) {
          return false;
        }

        return true;
      },

      eventDrop: (info) => {
        const startMoment = toMoment(info.event.start!, this.calendar);

        this.updateTimeEntry(
          info.event.id,
          startMoment.format('YYYY-MM-DD'),
          info.event.allDay ? null : startMoment.format('HH:mm'),
          info.event.extendedProps.hours as number,
          info.revert,
        );

        if (!info.event.allDay) {
          info.event.setEnd(
            startMoment
              .add(info.event.extendedProps.hours as number, 'hours')
              .toDate(),
          );
        }

        // mark the event explicitly as resizable if it is not an all day event
        info.event.setProp('durationEditable', !info.event.allDay);

        this.calendar.setOption('defaultTimedEventDuration', this.DEFAULT_TIMED_EVENT_DURATION);
      },
      eventClick: (info) => {
        // A link in the card leads somewhere of its own, and the click can land on an icon
        // inside it rather than on the anchor.
        if ((info.jsEvent.target as HTMLElement).closest('a[href]')) {
          return;
        }

        void this.turboRequests.request(
          `${this.pathHelperService.timeEntryEditDialog(info.event.id)}?onlyMe=true`,
          { method: 'GET' },
        );
      },
      viewDidMount: () => { setTimeout(() => this.addTotalFooter(), 100); },
      eventDidMount: () => { setTimeout(() => this.addTotalFooter(), 100); },
      eventChange: () => { setTimeout(() => this.addTotalFooter(), 100); },
    });

    this.calendar.render();
  }

  createEventContent(info:EventContentArg) {
    const entry = { ...info.event.extendedProps, id: info.event.id } as TimeEntryCard;

    // While the event is being resized the serialized duration and time range describe
    // where it came from, so they are recomputed from what is on screen.
    if (info.isResizing && info.event.start && info.event.end) {
      return renderTimeEntryCard(
        { ...entry, hours: this.calculateHours(info.event), timeRange: this.resizedTimeRange(info.event) },
        this.pathHelperService,
      );
    }

    return renderTimeEntryCard(entry, this.pathHelperService);
  }

  resizedTimeRange(event:EventApi):string {
    const format = (date:Date) => toMoment(date, this.calendar).format('LT');

    return `${format(event.start!)} - ${format(event.end!)}`;
  }

  addTotalFooter() {
    if (!this.calendar) return;

    renderFooterTotals(document, (day) => displayDuration(this.calculateTotalHours(day)));
  }

  calculateTotalHours(dayStr:string):number {
    // Calculate total hours for this day
    let totalHours = 0;

    this.calendar.getEvents().forEach((event) => {
      const eventStart = event.start;
      if (!eventStart) return;

      // Format event date for comparison
      const eventDateStr = toMoment(eventStart, this.calendar).format('YYYY-MM-DD');

      if (eventDateStr === dayStr && event.extendedProps?.hours) {
        totalHours += event.extendedProps.hours as number;
      }
    });

    return totalHours;
  }

  updateTimeEntry(timeEntryId:string, spentOn:string, startTime:string|null, hours:number, revertFunction:() => void) {
    fetch(this.pathHelperService.timeEntryUpdate(timeEntryId), {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken,
      },
      body: JSON.stringify({
        time_entry: {
          spent_on: spentOn,
          start_time: startTime,
          hours,
        },
        no_dialog: true,
      }),
    })
      .then((response) => {
        void response.text().then((html) => {
          renderStreamMessage(html);
        });
        if (!response.ok && revertFunction) {
          revertFunction();
        }
      })
      .catch(() => {
        if (revertFunction) {
          revertFunction();
        }
      });
  }

  calculateHours(event:EventApi):number {
    const start = event.start;
    const end = event.end;

    if (!start || !end) {
      return 0;
    }

    const startMoment = toMoment(start, this.calendar);
    const endMoment = toMoment(end, this.calendar);

    return moment.duration(endMoment.diff(startMoment)).asHours();
  }

  calendarView():string {
    switch (this.modeValue) {
      case 'week':
      case 'workweek':
        return 'timeGridWeek';
      case 'month':
        return 'dayGridMonth';
      case 'day':
        return 'timeGridDay';
      default:
        return 'timeGridWeek';
    }
  }

  hiddenDays():number[] {
    // if we are not in workweek mode we do not hide any days
    if (this.modeValue !== 'workweek') {
      return [];
    }

    const hiddenDays = [0, 1, 2, 3, 4, 5, 6];
    this.workingDaysValue.forEach((day) => {
      const index = hiddenDays.indexOf(day);
      if (index > -1) {
        hiddenDays.splice(index, 1);
      }
    });

    return hiddenDays;
  }

  async newTimeEntry(event:ActionEvent) {
    const dialogParams = `onlyMe=true&date=${event.params.date}`;

    const { turboRequests, pathHelperService } = await this.services;
    void turboRequests.request(
      `${pathHelperService.timeEntryDialog()}?${dialogParams}`,
      { method: 'GET' },
    );
  }

  dialogCloseListener(event:CustomEvent<DialogCloseDetail<AdditionalDialogCloseData>>):void {
    const { detail: { dialog, additional, submitted } } = event;
    if (dialog.id !== 'time-entry-dialog' || !submitted) { return; }

    // we simply refresh the calendar page
    if (this.viewModeValue === 'calendar') {
      window.location.reload();
      return;
    }

    // list view replaces only the updated date
    if (this.viewModeValue === 'list') {
      // we don't know what date we clicked, so we need to reload the whole page
      if (additional?.spent_on) {
        void this.turboRequests.request(this.pathHelperService.myTimeTrackingRefresh(additional.spent_on, this.viewModeValue, this.modeValue), { method: 'GET' });
      } else {
        window.location.reload();
      }
    }
  }
}
