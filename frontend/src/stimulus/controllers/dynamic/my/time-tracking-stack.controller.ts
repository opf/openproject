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
import { html, render, TemplateResult } from 'lit-html';
import { unsafeHTML } from 'lit-html/directives/unsafe-html.js';
import { clockIconData, toDOMString } from '@openproject/octicons-angular';
import { renderFooterTotals } from 'core-stimulus/helpers/fullcalendar-footer-helpers';

// Mirrors the fields of FullCalendar::TimeEntryEvent the stack uses; the calendar view is
// served the same payload.
interface StackTimeEntry {
  id:string;
  start:string;
  hours:number;
  title:string;
  typeId:number;
  workPackageSubject:string;
  projectName:string;
}

const TIME_ENTRY_CLASS_NAME = 'te-stack--time-entry';
const WORKING_HOURS_CLASS_NAME = 'te-stack--working-hours';

// The stack is a timeGrid abused as a stacked bar chart, so these bound an axis of hours
// logged rather than clock times, and the scale ratio compresses a day that exceeds them.
const MIN_HOUR = 1;
const MAX_HOUR = 12;
const LABEL_INTERVAL_HOURS = 2;
const MS_PER_HOUR = 60 * 60 * 1000;
const DAY_IN_MS = 24 * MS_PER_HOUR;

// A bar thinner than this leaves no room for its own duration once the card is padded.
// Applied after the scale ratio, so that it stays a constant height on screen.
const MIN_BAR_HOURS = 0.75;

export default class MyTimeTrackingStackController extends Controller {
  static services:ServiceKey[] = ['turboRequests', 'pathHelperService'];

  declare turboRequests:TurboRequestsService;
  declare pathHelperService:PathHelperService;
  declare services:Promise<PickedServices<'turboRequests'|'pathHelperService'>>;

  static targets = ['stack'];

  static values = {
    mode: String,
    timeEntries: Array,
    initialDate: String,
    canCreate: Boolean,
    locale: String,
    workingDays: Array,
    workingHours: Object,
    startOfWeek: Number,
    timeZone: String,
  };

  declare readonly stackTarget:HTMLElement;
  declare readonly hasStackTarget:boolean;
  declare readonly modeValue:string;
  declare readonly timeEntriesValue:StackTimeEntry[];
  declare readonly initialDateValue:string;
  declare readonly canCreateValue:boolean;
  declare readonly localeValue:string;
  declare readonly workingDaysValue:number[];
  declare readonly workingHoursValue:Record<string, number>;
  declare readonly startOfWeekValue:number;
  declare readonly timeZoneValue:string;

  private calendar:Calendar;
  private scaleRatio = 1;
  private resizeObserver:ResizeObserver;
  private lastWidth = 0;
  private boundListener = this.dialogCloseListener.bind(this);

  initialize() {
    useAngularServices(this);
  }

  servicesConnected() {
    if (this.hasStackTarget) {
      this.initializeStack();
    }

    document.addEventListener('dialog:close', this.boundListener);
  }

  disconnect():void {
    document.removeEventListener('dialog:close', this.boundListener);

    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }

    if (this.calendar) {
      this.calendar.destroy();
    }
  }

  // FullCalendar keeps whatever column widths it measured on its first layout, so a
  // container that is still settling would leave the columns collapsed for good.
  private observeResize():void {
    this.resizeObserver = new ResizeObserver(() => {
      const width = this.stackTarget.clientWidth;

      if (width === this.lastWidth) {
        return;
      }

      this.lastWidth = width;
      this.calendar.updateSize();
      this.addTotalFooter();
    });

    this.resizeObserver.observe(this.stackTarget);
  }

  initializeStack() {
    this.setRatio();

    this.calendar = new Calendar(this.stackTarget, {
      plugins: [timeGridPlugin, interactionPlugin],
      initialView: this.stackView(),
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
      eventShortHeight: 80,
      slotMinTime: `${MIN_HOUR - 1}:00:00`,
      slotMaxTime: `${MAX_HOUR}:00:00`,
      slotLabelInterval: `${LABEL_INTERVAL_HOURS}:00:00`,
      slotLabelFormat: (info:VerboseFormattingArg) => displayDuration((MAX_HOUR - info.date.hour) / this.scaleRatio),
      events: (fetchInfo, successCallback) => successCallback(this.buildEvents(fetchInfo.startStr, fetchInfo.endStr)),
      eventOverlap: (stillEvent) => !stillEvent.classNames.includes(TIME_ENTRY_CLASS_NAME),
      eventContent: (info) => this.eventContent(info.event.extendedProps),
      eventClick: (info) => this.handleEventClick(info.event.extendedProps),
      selectable: this.canCreateValue,
      select: (info) => this.newTimeEntry(info.startStr.slice(0, 10), this.selectedHours(info.start, info.end)),
    });

    this.calendar.render();
    this.addTotalFooter();
    this.observeResize();
  }

  private buildEvents(startStr:string, endStr:string):EventInput[] {
    return this.buildTimeEntryEvents().concat(this.buildWorkingHoursEvents(startStr, endStr));
  }

  private buildTimeEntryEvents():EventInput[] {
    const stackTops:Record<string, number> = {};

    return this.timeEntriesValue.map((entry) => {
      const day = this.dayOf(entry);
      const endHour = stackTops[day] ?? MAX_HOUR;
      const hours = Math.max(entry.hours * this.scaleRatio, MIN_BAR_HOURS);
      // A day made up of many tiny entries can outgrow the axis once they are floored.
      const startHour = Math.max(endHour - hours, 0);

      stackTops[day] = startHour;

      return this.timeEntryEvent(entry, day, startHour, endHour);
    });
  }

  // The server builds an event's start from spent_on in the entry's own time zone and
  // serializes it with that offset, so the date part never depends on where it is read.
  private dayOf(entry:StackTimeEntry):string {
    return entry.start.slice(0, 10);
  }

  private buildWorkingHoursEvents(startStr:string, endStr:string):EventInput[] {
    return this.daysBetween(startStr, endStr)
      .filter((day) => (this.workingHoursValue[day] || 0) > 0)
      .map((day) => this.workingHoursEvent(day, this.workingHoursValue[day]));
  }

  private workingHoursEvent(day:string, scheduled:number):EventInput {
    return {
      start: this.slotTime(day, Math.max(MAX_HOUR - (scheduled * this.scaleRatio), 0)),
      end: this.slotTime(day, MAX_HOUR),
      display: 'background' as const,
      classNames: [WORKING_HOURS_CLASS_NAME],
    };
  }

  private addTotalFooter():void {
    const dateSums = this.calculateDateSums();

    renderFooterTotals(this.element, (day) => this.footerContent(dateSums[day] || 0, this.workingHoursValue[day] || 0));

    // The footer is appended after FullCalendar has laid the view out, so without this the
    // slots keep the full height and run underneath it.
    this.calendar.updateSize();
  }

  private footerContent(logged:number, scheduled:number):Node {
    const clock = toDOMString(clockIconData, 'small', {
      'aria-hidden': 'true',
      class: 'octicon',
    });

    const wrapper = document.createElement('div');
    render(
      html`
        <div class="te-stack--footer">
          <span class="te-stack--footer-icon">${unsafeHTML(clock)}</span>
          <span>${displayDuration(logged)}</span>
          ${scheduled > 0 ? html`<span class="te-stack--footer-scheduled">${displayDuration(scheduled)}</span>` : ''}
        </div>`,
      wrapper,
    );

    return wrapper;
  }

  private timeEntryEvent(entry:StackTimeEntry, day:string, startHour:number, endHour:number):EventInput {
    return {
      id: entry.id,
      title: entry.title,
      start: this.slotTime(day, startHour),
      end: this.slotTime(day, endHour),
      classNames: [
        TIME_ENTRY_CLASS_NAME,
        '__hl_border_top',
        Highlighting.resourceClass('type', entry.typeId),
      ],
      extendedProps: { entry },
    };
  }

  private eventContent(props:Record<string, unknown>):{ domNodes:Node[] }|undefined {
    const entry = props.entry as StackTimeEntry|undefined;

    if (!entry) {
      return undefined;
    }

    const wrapper = document.createElement('div');
    wrapper.classList.add('fc-event-main-frame');
    render(this.cardContent(entry), wrapper);

    return { domNodes: [wrapper] };
  }

  private cardContent(entry:StackTimeEntry):TemplateResult {
    const clock = toDOMString(clockIconData, 'small', {
      'aria-hidden': 'true',
      class: 'octicon',
    });

    return html`
      <div class="te-stack--card">
        <div class="te-stack--card-duration">${displayDuration(entry.hours)}</div>
        <div class="te-stack--card-subject">${entry.workPackageSubject}</div>
        <div class="te-stack--card-project">${entry.projectName}</div>
        <div class="te-stack--card-icon">${unsafeHTML(clock)}</div>
      </div>`;
  }

  private handleEventClick(props:Record<string, unknown>):void {
    const entry = props.entry as StackTimeEntry|undefined;

    if (!entry) {
      return;
    }

    void this.turboRequests.request(
      `${this.pathHelperService.timeEntryEditDialog(entry.id)}?onlyMe=true`,
      { method: 'GET' },
    );
  }

  // A selection spans slots on an axis of hours logged, so its length is the duration to
  // log once the scale ratio is undone.
  private selectedHours(start:Date, end:Date):number {
    const spanned = (end.getTime() - start.getTime()) / MS_PER_HOUR;

    return Math.round((spanned / this.scaleRatio) * 100) / 100;
  }

  private newTimeEntry(day:string, hours:number):void {
    void this.turboRequests.request(
      `${this.pathHelperService.timeEntryDialog()}?onlyMe=true&date=${day}&hours=${hours}`,
      { method: 'GET' },
    );
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

  // A naive ISO timestamp, which FullCalendar resolves in its own time zone.
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

  // The stack has no month view; the controller sends a month request to the work week.
  private stackView():string {
    return this.modeValue === 'day' ? 'timeGridDay' : 'timeGridWeek';
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
