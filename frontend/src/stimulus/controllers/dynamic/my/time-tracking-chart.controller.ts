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

import { Controller } from '@hotwired/stimulus';
import { Calendar, EventInput } from '@fullcalendar/core';
import { VerboseFormattingArg } from '@fullcalendar/common';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import allLocales from '@fullcalendar/core/locales-all';
import type { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import type { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';
import { DialogCloseDetail } from 'core-turbo/dialog-stream-action';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { displayDuration } from 'core-stimulus/helpers/duration-helpers';

// The subset of FullCalendar::TimeEntryEvent the chart reads. The calendar view is served
// the same payload, so the two stay in sync; the chart ignores the event's own start and
// end and stacks its bars from the day and the hours instead.
interface ChartTimeEntry {
  id:string;
  start:string;
  hours:number;
  title:string;
  typeId:number;
}

const TIME_ENTRY_CLASS_NAME = 'te-chart--time-entry';
const DAY_SUM_CLASS_NAME = 'te-chart--day-sum';
const ADD_ENTRY_CLASS_NAME = 'te-chart--add-entry';
const ADD_ICON_CLASS_NAME = 'te-chart--add-icon';
const ADD_ENTRY_PROHIBITED_CLASS_NAME = '-prohibited';

// The chart is a timeGrid abused as a stacked bar chart: every day is a column and its
// entries are stacked downwards from maxHour. The slot labels therefore show hours, not
// times, and the scale ratio compresses the stack once a day exceeds the visible range.
const MIN_HOUR = 1;
const MAX_HOUR = 12;
const LABEL_INTERVAL_HOURS = 2;
const DAY_IN_MS = 24 * 60 * 60 * 1000;

export default class MyTimeTrackingChartController extends Controller {
  static services:ServiceKey[] = ['turboRequests', 'pathHelperService'];

  declare turboRequests:TurboRequestsService;
  declare pathHelperService:PathHelperService;
  declare services:Promise<PickedServices<'turboRequests'|'pathHelperService'>>;

  static targets = ['chart'];

  static values = {
    mode: String,
    timeEntries: Array,
    initialDate: String,
    canCreate: Boolean,
    locale: String,
    workingDays: Array,
    startOfWeek: Number,
    timeZone: String,
  };

  declare readonly chartTarget:HTMLElement;
  declare readonly hasChartTarget:boolean;
  declare readonly modeValue:string;
  declare readonly timeEntriesValue:ChartTimeEntry[];
  declare readonly initialDateValue:string;
  declare readonly canCreateValue:boolean;
  declare readonly localeValue:string;
  declare readonly workingDaysValue:number[];
  declare readonly startOfWeekValue:number;
  declare readonly timeZoneValue:string;

  private calendar:Calendar;
  private scaleRatio = 1;
  private boundListener = this.dialogCloseListener.bind(this);

  initialize() {
    useAngularServices(this);
  }

  servicesConnected() {
    if (this.hasChartTarget) {
      this.initializeChart();

      // The stimulus controller gets initialized before the content wrapper is fully shown
      // so its height might not be set correctly yet.
      setTimeout(() => this.calendar.updateSize(), 25);
    }

    document.addEventListener('dialog:close', this.boundListener);
  }

  disconnect():void {
    document.removeEventListener('dialog:close', this.boundListener);

    if (this.calendar) {
      this.calendar.destroy();
    }
  }

  initializeChart() {
    this.setRatio();

    this.calendar = new Calendar(this.chartTarget, {
      plugins: [timeGridPlugin, interactionPlugin],
      views: {
        timeGridMonth: { type: 'timeGrid', duration: { months: 1 } },
      },
      initialView: this.chartView(),
      initialDate: this.initialDateValue,
      locales: allLocales,
      locale: this.localeValue,
      timeZone: this.timeZoneValue,
      firstDay: this.startOfWeekValue,
      hiddenDays: this.hiddenDays(),
      headerToolbar: false,
      height: '100%',
      expandRows: true,
      editable: false,
      allDaySlot: false,
      displayEventTime: false,
      slotEventOverlap: false,
      slotMinTime: `${MIN_HOUR - 1}:00:00`,
      slotMaxTime: `${MAX_HOUR}:00:00`,
      slotLabelInterval: `${LABEL_INTERVAL_HOURS}:00:00`,
      slotLabelFormat: (info:VerboseFormattingArg) => ((MAX_HOUR - info.date.hour) / this.scaleRatio).toString(),
      events: (fetchInfo, successCallback) => successCallback(this.buildEvents(fetchInfo.startStr, fetchInfo.endStr)),
      eventOverlap: (stillEvent) => !stillEvent.classNames.includes(TIME_ENTRY_CLASS_NAME),
      eventDidMount: (info) => this.decorateEvent(info.el, info.event.extendedProps),
      eventClick: (info) => this.handleEventClick(info.el, info.event.startStr, info.event.extendedProps),
    });

    this.calendar.render();
  }

  private buildEvents(startStr:string, endStr:string):EventInput[] {
    return this.buildTimeEntryEvents().concat(this.buildAuxEvents(startStr, endStr));
  }

  // Entries are laid out top-down per day, each one ending where the previous one started.
  private buildTimeEntryEvents():EventInput[] {
    const stackTops:Record<string, number> = {};

    return this.timeEntriesValue.map((entry) => {
      const day = this.dayOf(entry);
      const endHour = stackTops[day] ?? MAX_HOUR;
      const startHour = endHour - (entry.hours * this.scaleRatio);

      stackTops[day] = startHour;

      return this.timeEntryEvent(entry, day, startHour, endHour);
    });
  }

  // An event's start always carries its spent_on date: the server builds the timestamp
  // from spent_on in the entry's own time zone and serializes it with that zone's offset,
  // so the date part never depends on where it is read.
  private dayOf(entry:ChartTimeEntry):string {
    return entry.start.slice(0, 10);
  }

  private buildAuxEvents(startStr:string, endStr:string):EventInput[] {
    const dateSums = this.calculateDateSums();
    const events:EventInput[] = [];

    this.daysBetween(startStr, endStr).forEach((day) => {
      const duration = dateSums[day] || 0;

      events.push(this.sumEvent(day, duration));

      if (this.canCreateValue) {
        events.push(this.addEvent(day, duration));
      }
    });

    return events;
  }

  private timeEntryEvent(entry:ChartTimeEntry, day:string, startHour:number, endHour:number):EventInput {
    const span = (endHour - startHour) * 60;
    const classNames = [
      TIME_ENTRY_CLASS_NAME,
      ...Highlighting.backgroundClass('type', entry.typeId).split(' '),
    ];

    if (span < 40) {
      classNames.push('-no-fadeout');
    }

    return {
      id: entry.id,
      title: span < 20 ? '' : entry.title,
      start: this.slotTime(day, startHour),
      end: this.slotTime(day, endHour),
      classNames,
      extendedProps: { entry },
    };
  }

  private sumEvent(day:string, duration:number):EventInput {
    return {
      start: this.slotTime(day, MAX_HOUR - Math.min(duration * this.scaleRatio, MAX_HOUR - 0.5) - 0.5),
      end: this.slotTime(day, MAX_HOUR - Math.min((duration + 0.05) * this.scaleRatio, MAX_HOUR - 0.5)),
      display: 'background' as const,
      classNames: [DAY_SUM_CLASS_NAME],
      extendedProps: { sum: String(I18n.t('js.units.hour_string', { hours: duration.toFixed(2) })) },
    };
  }

  private addEvent(day:string, duration:number):EventInput {
    const classNames = [ADD_ENTRY_CLASS_NAME];

    if (duration >= 24) {
      classNames.push(ADD_ENTRY_PROHIBITED_CLASS_NAME);
    }

    return {
      start: this.slotTime(day, 0),
      end: this.slotTime(day, MAX_HOUR - Math.min(duration * this.scaleRatio, MAX_HOUR - 1) - 0.5),
      display: 'background' as const,
      classNames,
    };
  }

  private decorateEvent(element:HTMLElement, props:Record<string, unknown>):void {
    if (element.classList.contains(ADD_ENTRY_CLASS_NAME)) {
      const addIcon = document.createElement('div');
      addIcon.classList.add(ADD_ICON_CLASS_NAME);
      addIcon.innerText = '+';
      element.append(addIcon);
      return;
    }

    if (props.sum) {
      element.innerHTML = props.sum as string;
      return;
    }

    const entry = props.entry as ChartTimeEntry|undefined;
    if (!entry || entry.hours < 0.5) {
      return;
    }

    this.prependDuration(element, entry);
    this.appendFadeout(element);
  }

  private prependDuration(element:HTMLElement, entry:ChartTimeEntry):void {
    element
      .querySelector('.fc-event-title')
      ?.insertAdjacentHTML('afterbegin', `<div class="fc-duration">${displayDuration(entry.hours)}</div>`);
  }

  /* Fade out event text to the bottom to avoid it being cut off weirdly.
   * Multiline ellipsis with an unknown height is not possible, hence we blur the text.
   */
  private appendFadeout(element:HTMLElement):void {
    const fadeout = document.createElement('div');
    fadeout.classList.add('fc-fadeout');

    element.append(fadeout);
  }

  private handleEventClick(element:HTMLElement, startStr:string, props:Record<string, unknown>):void {
    const entry = props.entry as ChartTimeEntry|undefined;

    if (entry) {
      void this.turboRequests.request(
        `${this.pathHelperService.timeEntryEditDialog(entry.id)}?onlyMe=true`,
        { method: 'GET' },
      );
      return;
    }

    if (element.classList.contains(ADD_ENTRY_CLASS_NAME) && !element.classList.contains(ADD_ENTRY_PROHIBITED_CLASS_NAME)) {
      void this.turboRequests.request(
        `${this.pathHelperService.timeEntryDialog()}?onlyMe=true&date=${startStr.slice(0, 10)}`,
        { method: 'GET' },
      );
    }
  }

  private calculateDateSums():Record<string, number> {
    const sums:Record<string, number> = {};

    this.timeEntriesValue.forEach((entry) => {
      const day = this.dayOf(entry);
      sums[day] = (sums[day] || 0) + entry.hours;
    });

    return sums;
  }

  private setRatio():void {
    const maxHours = Math.max(...Object.values(this.calculateDateSums()), 0);

    if (maxHours > MAX_HOUR - MIN_HOUR) {
      this.scaleRatio = this.smallerSuitableRatio((MAX_HOUR - MIN_HOUR) / maxHours);
    } else {
      this.scaleRatio = 1;
    }
  }

  private smallerSuitableRatio(value:number):number {
    for (let divisor = LABEL_INTERVAL_HOURS + 1; divisor < 100; divisor++) {
      const candidate = LABEL_INTERVAL_HOURS / divisor;

      if (value >= candidate) {
        return candidate;
      }
    }

    return 1;
  }

  // A naive ISO timestamp, which FullCalendar resolves in its own time zone. Building one
  // from an offset Date instead would shift the event by the browser's UTC offset.
  private slotTime(day:string, hoursFromMidnight:number):string {
    const seconds = Math.round(hoursFromMidnight * 3600);
    const pad = (value:number) => value.toString().padStart(2, '0');

    return `${day}T${pad(Math.floor(seconds / 3600))}:${pad(Math.floor(seconds / 60) % 60)}:${pad(seconds % 60)}`;
  }

  // Walked in UTC so that neither the browser's time zone nor a DST transition can drop
  // or duplicate a day.
  private daysBetween(startStr:string, endStr:string):string[] {
    const days:string[] = [];
    const end = Date.parse(`${endStr.slice(0, 10)}T00:00:00Z`);

    for (let day = Date.parse(`${startStr.slice(0, 10)}T00:00:00Z`); day < end; day += DAY_IN_MS) {
      days.push(new Date(day).toISOString().slice(0, 10));
    }

    return days;
  }

  private chartView():string {
    switch (this.modeValue) {
      case 'day':
        return 'timeGridDay';
      case 'month':
        return 'timeGridMonth';
      default:
        return 'timeGridWeek';
    }
  }

  private hiddenDays():number[] {
    if (this.modeValue !== 'workweek') {
      return [];
    }

    return [0, 1, 2, 3, 4, 5, 6].filter((day) => !this.workingDaysValue.includes(day));
  }

  private dialogCloseListener(event:CustomEvent<DialogCloseDetail>):void {
    const { detail: { dialog, submitted } } = event;

    if (dialog.id === 'time-entry-dialog' && submitted) {
      window.location.reload();
    }
  }
}
