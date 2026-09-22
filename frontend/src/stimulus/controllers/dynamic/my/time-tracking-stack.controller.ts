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

// The subset of FullCalendar::TimeEntryEvent the stack reads. The calendar view is served
// the same payload, so the two stay in sync; the stack ignores the event's own start and
// end and stacks its bars from the day and the hours instead.
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
const ADD_ENTRY_CLASS_NAME = 'te-stack--add-entry';
const ADD_ICON_CLASS_NAME = 'te-stack--add-icon';
const ADD_ENTRY_PROHIBITED_CLASS_NAME = '-prohibited';

// The stack is a timeGrid abused as a stacked bar chart: every day is a column and its
// entries are stacked downwards from maxHour. The slot labels therefore show hours, not
// times, and the scale ratio compresses the stack once a day exceeds the visible range.
const MIN_HOUR = 1;
const MAX_HOUR = 12;
const LABEL_INTERVAL_HOURS = 2;
const DAY_IN_MS = 24 * 60 * 60 * 1000;

// A bar thinner than this has no room left for its own duration once the card is padded,
// so short entries are drawn at this height and the rest of the stack moves up with them.
// It is applied after the scale ratio so that it stays a roughly constant height on screen.
const MIN_BAR_HOURS = 0.5;

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

  /*
   * FullCalendar keeps whatever column widths it measured on its first layout, so a
   * container that is still settling leaves the columns collapsed for good. The observer
   * re-measures as soon as the container reaches its real width, which also covers the
   * side menu collapsing, zen mode and window resizes.
   *
   * It runs after layout but before paint, so the correction lands on the first frame
   * rather than flickering, and unlike requestAnimationFrame it also fires while the tab
   * is in the background.
   */
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
      // Below this FullCalendar marks the event short, which drops the card to the lines
      // that still fit.
      eventShortHeight: 80,
      slotMinTime: `${MIN_HOUR - 1}:00:00`,
      slotMaxTime: `${MAX_HOUR}:00:00`,
      slotLabelInterval: `${LABEL_INTERVAL_HOURS}:00:00`,
      // The axis counts hours logged, not times, so the labels run from MAX_HOUR down.
      slotLabelFormat: (info:VerboseFormattingArg) => displayDuration((MAX_HOUR - info.date.hour) / this.scaleRatio),
      events: (fetchInfo, successCallback) => successCallback(this.buildEvents(fetchInfo.startStr, fetchInfo.endStr)),
      eventOverlap: (stillEvent) => !stillEvent.classNames.includes(TIME_ENTRY_CLASS_NAME),
      eventContent: (info) => this.eventContent(info.event.extendedProps),
      eventDidMount: (info) => this.decorateBackgroundEvent(info.el),
      eventClick: (info) => this.handleEventClick(info.el, info.event.startStr, info.event.extendedProps),
    });

    this.calendar.render();
    this.addTotalFooter();
    this.observeResize();
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
      const hours = Math.max(entry.hours * this.scaleRatio, MIN_BAR_HOURS);
      // A day made up of many tiny entries can outgrow the axis once they are floored.
      const startHour = Math.max(endHour - hours, 0);

      stackTops[day] = startHour;

      return this.timeEntryEvent(entry, day, startHour, endHour);
    });
  }

  // An event's start always carries its spent_on date: the server builds the timestamp
  // from spent_on in the entry's own time zone and serializes it with that zone's offset,
  // so the date part never depends on where it is read.
  private dayOf(entry:StackTimeEntry):string {
    return entry.start.slice(0, 10);
  }

  private buildAuxEvents(startStr:string, endStr:string):EventInput[] {
    const dateSums = this.calculateDateSums();
    const events:EventInput[] = [];

    this.daysBetween(startStr, endStr).forEach((day) => {
      if (this.canCreateValue) {
        events.push(this.addEvent(day, dateSums[day] || 0));
      }
    });

    return events;
  }

  private addTotalFooter():void {
    const dateSums = this.calculateDateSums();

    renderFooterTotals(this.element, (day) => displayDuration(dateSums[day] || 0));

    // The footer row is appended to the scrollgrid after FullCalendar has laid the view
    // out, so the slots still occupy the full height and would run underneath it.
    this.calendar.updateSize();
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

  // Background events render no content of their own, so they keep FullCalendar's default
  // and are decorated on mount instead.
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

  private decorateBackgroundEvent(element:HTMLElement):void {
    if (!element.classList.contains(ADD_ENTRY_CLASS_NAME)) {
      return;
    }

    const addIcon = document.createElement('div');
    addIcon.classList.add(ADD_ICON_CLASS_NAME);
    addIcon.innerText = '+';
    element.append(addIcon);
  }

  private handleEventClick(element:HTMLElement, startStr:string, props:Record<string, unknown>):void {
    const entry = props.entry as StackTimeEntry|undefined;

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
