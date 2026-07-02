/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller, ActionEvent } from '@hotwired/stimulus';
import { Calendar, EventInput } from '@fullcalendar/core';
import interactionPlugin from '@fullcalendar/interaction';
import resourceTimelinePlugin from '@fullcalendar/resource-timeline';
import { ResourceInput } from '@fullcalendar/resource';
import allLocales from '@fullcalendar/core/locales-all';
import { renderStreamMessage } from '@hotwired/turbo';
import { TurboHelpers } from 'core-turbo/helpers';
import moment from 'moment';

// Every granularity view shares the same shape, only the unit changes: a fixed
// span of equal-width columns, one calendar unit per column, paging by half the
// span so consecutive pages overlap and keep context.
const COLUMNS_PER_VIEW = 10;
const UNITS_PER_COLUMN = 1;
const COLUMNS_PER_PAGE = COLUMNS_PER_VIEW / 2;

// When centering on today, keep a few columns of past in view so today sits near
// the start of the span and most of the width shows upcoming work.
const COLUMNS_BEFORE_TODAY = 3;

// Per FullCalendar view: the granularity key sent to the feed and the moment unit
// of one column. The only view names in play are the three registered below; the
// day view doubles as the fallback (matching the server's default granularity).
const GRANULARITY_VIEWS:Record<string, { granularity:string, unit:moment.unitOfTime.DurationConstructor }> = {
  resourceTimelineDays: { granularity: 'day', unit: 'days' },
  resourceTimelineWeeks: { granularity: 'week', unit: 'weeks' },
  resourceTimelineMonths: { granularity: 'month', unit: 'months' },
};
const DEFAULT_GRANULARITY_VIEW = GRANULARITY_VIEWS.resourceTimelineDays;

export default class WorkPackageTimelineController extends Controller {
  static targets = ['calendar', 'granularityButton'];

  static values = {
    resourcesUrl: String,
    eventsUrl: String,
    locale: String,
    firstDay: Number,
    initialDate: String,
    initialView: String,
    newAllocationUrl: String,
    reloadEventName: String,
  };

  declare readonly calendarTarget:HTMLElement;
  declare readonly hasGranularityButtonTarget:boolean;
  declare readonly granularityButtonTarget:HTMLElement;
  declare readonly resourcesUrlValue:string;
  declare readonly eventsUrlValue:string;
  declare readonly localeValue:string;
  declare readonly firstDayValue:number;
  declare readonly initialDateValue:string;
  declare readonly initialViewValue:string;
  declare readonly newAllocationUrlValue:string;
  declare readonly reloadEventNameValue:string;

  private calendar?:Calendar;

  // Refetches both feeds in place when the server signals an allocation change,
  // so the calendar updates without reloading (and re-instantiating) the frame.
  private readonly reloadListener = ():void => {
    this.calendar?.refetchResources();
    this.calendar?.refetchEvents();
  };

  // Sent to the events feed. Updated before changeView because FullCalendar fires
  // the fetch mid-transition, while `calendar.view` still reports the old view.
  private currentGranularity:string;

  connect() {
    if (this.reloadEventNameValue) {
      document.addEventListener(this.reloadEventNameValue, this.reloadListener);
    }

    // Defer to the next frame so the container has its final size before
    // FullCalendar measures it.
    requestAnimationFrame(() => this.initializeCalendar());
  }

  disconnect() {
    if (this.reloadEventNameValue) {
      document.removeEventListener(this.reloadEventNameValue, this.reloadListener);
    }

    if (this.calendar) {
      this.calendar.destroy();
      this.calendar = undefined;
    }
  }

  prev() { this.calendar?.prev(); }

  next() { this.calendar?.next(); }

  today() { this.centerOnToday(); }

  // The granularity menu items carry `view` (e.g. resourceTimelineWeeks) and
  // `label` (e.g. "Calendar week") action params.
  setView(event:ActionEvent) {
    if (!this.calendar) { return; }

    this.currentGranularity = this.granularityKeyFor(event.params.view as string);
    this.calendar.changeView(event.params.view as string);
    this.centerOnToday();
    this.updateGranularityLabel(event.params.label as string);
  }

  private initializeCalendar() {
    // Computed up front so the first render is already centered on today, with no
    // post-render gotoDate that would trigger a second feed fetch.
    const initialDate = this.startCenteredOnToday(this.initialViewValue);

    this.currentGranularity = this.granularityKeyFor(this.initialViewValue);

    this.calendar = new Calendar(this.calendarTarget, {
      schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
      plugins: [resourceTimelinePlugin, interactionPlugin],
      initialView: this.initialViewValue,
      initialDate,
      // Custom views, rather than FullCalendar's built-in ones that zoom into
      // hour or day slots (see the column constants above).
      views: {
        resourceTimelineDays: {
          type: 'resourceTimeline',
          duration: { days: COLUMNS_PER_VIEW },
          slotDuration: { days: UNITS_PER_COLUMN },
          dateIncrement: { days: COLUMNS_PER_PAGE },
          slotLabelFormat: { weekday: 'short', month: 'numeric', day: 'numeric' },
        },
        resourceTimelineWeeks: {
          type: 'resourceTimeline',
          duration: { weeks: COLUMNS_PER_VIEW },
          slotDuration: { weeks: UNITS_PER_COLUMN },
          dateIncrement: { weeks: COLUMNS_PER_PAGE },
          slotLabelFormat: { week: 'long' },
        },
        resourceTimelineMonths: {
          type: 'resourceTimeline',
          duration: { months: COLUMNS_PER_VIEW },
          slotDuration: { months: UNITS_PER_COLUMN },
          dateIncrement: { months: COLUMNS_PER_PAGE },
          slotLabelFormat: { month: 'short' },
        },
      },
      locales: allLocales,
      locale: this.localeValue,
      firstDay: this.firstDayValue,
      headerToolbar: false,
      nowIndicator: true,
      height: '100%',
      // The feed's output depends on the granularity, not just the date range, so
      // refetch on every navigation instead of reusing FullCalendar's cache.
      lazyFetching: false,
      resourceAreaColumns: [{
        headerContent: '',
        cellContent: (arg) => ({ html: (arg.resource?.extendedProps?.html as string) || '' }),
      }],
      resourceOrder: 'order',
      resources: (_info, success, failure) => {
        fetch(this.resourcesUrlValue, { headers: { Accept: 'application/json' } })
          .then((response) => response.json())
          .then((data:{ resources:ResourceInput[] }) => success(data.resources))
          .catch(failure);
      },
      events: (info, success, failure) => {
        const url = new URL(this.eventsUrlValue, window.location.origin);
        url.searchParams.set('start', info.startStr);
        url.searchParams.set('end', info.endStr);
        url.searchParams.set('granularity', this.currentGranularity);
        fetch(url.toString(), { headers: { Accept: 'application/json' } })
          .then((response) => response.json())
          .then((data:{ events:EventInput[] }) => success(data.events))
          .catch(failure);
      },
      eventContent: (arg) => ({ html: (arg.event.extendedProps.html as string) || '' }),
      eventClassNames: (arg) => [
        arg.event.extendedProps.overbooked ? 'resource-allocation--overbooked' : '',
        arg.event.extendedProps.editUrl ? 'resource-allocation--editable' : '',
      ].filter(Boolean),
      eventsSet: () => { this.markActiveColumns(); },
      // Blank when the user may not allocate (the server omits the URL), so a
      // present URL is also the permission signal.
      selectable: this.newAllocationUrlValue.length > 0,
      select: (info) => {
        // FullCalendar's end is exclusive; step back one day for the inclusive end.
        const inclusiveEnd = moment(info.endStr).subtract(1, 'day').format('YYYY-MM-DD');
        const url = new URL(this.newAllocationUrlValue, window.location.origin);
        url.searchParams.set('work_package_id', info.resource?.id ?? '');
        url.searchParams.set('start_date', info.startStr);
        url.searchParams.set('end_date', inclusiveEnd);
        this.openDialog(url.toString());
        this.calendar?.unselect();
      },
      // The feed only sets editUrl on allocation bars the user may edit, so
      // background spans and read-only bars carry none and stay inert.
      eventClick: (info) => {
        const editUrl = info.event.extendedProps.editUrl as string | undefined;
        if (editUrl) { this.openDialog(editUrl); }
      },
    });

    this.calendar.render();
  }

  private centerOnToday():void {
    if (!this.calendar) { return; }

    this.calendar.gotoDate(this.startCenteredOnToday(this.calendar.view.type));
  }

  // The start date that places today COLUMNS_BEFORE_TODAY columns into the span.
  // Takes the view type explicitly because the initial render computes this
  // before `this.calendar` exists.
  private startCenteredOnToday(viewType:string):string {
    return moment(this.initialDateValue)
      .subtract(COLUMNS_BEFORE_TODAY, this.unitForViewName(viewType))
      .format('YYYY-MM-DD');
  }

  // Mark each header column active when an active-span band covers it.
  // FullCalendar offers no header-colouring input, so we toggle the class
  // on the rendered header cells, depending on the union of active columns.
  private markActiveColumns():void {
    if (!this.calendar) { return; }

    const bands = this.calendar.getEvents()
      .filter((event) => event.display === 'background')
      .map((event) => ({ start: event.startStr, end: event.endStr }));

    this.calendarTarget
      .querySelectorAll('.fc-timeline-header .fc-timeline-slot-label[data-date]')
      .forEach((cell) => {
        const date = cell.getAttribute('data-date') ?? '';
        const active = bands.some((band) => band.start <= date && date < band.end);
        cell.classList.toggle('op-rm-active-col', active);
      });
  }

  private granularityKeyFor(viewType:string):string {
    return (GRANULARITY_VIEWS[viewType] ?? DEFAULT_GRANULARITY_VIEW).granularity;
  }

  private unitForViewName(view:string):moment.unitOfTime.DurationConstructor {
    return (GRANULARITY_VIEWS[view] ?? DEFAULT_GRANULARITY_VIEW).unit;
  }

  private updateGranularityLabel(label:string):void {
    if (!label || !this.hasGranularityButtonTarget) { return; }

    const labelElement = this.granularityButtonTarget.querySelector('.Button-label');
    if (labelElement) { labelElement.textContent = label; }
  }

  private openDialog(url:string):void {
    TurboHelpers.showProgressBar();

    void fetch(url, { headers: { Accept: 'text/vnd.turbo-stream.html' } })
      .then((response) => response.text())
      .then((html) => { renderStreamMessage(html); })
      .finally(() => { TurboHelpers.hideProgressBar(); });
  }
}
