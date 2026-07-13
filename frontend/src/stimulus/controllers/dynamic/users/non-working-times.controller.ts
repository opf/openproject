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

import { Controller } from '@hotwired/stimulus';
import { Calendar } from '@fullcalendar/core';
import interactionPlugin from '@fullcalendar/interaction';
import multiMonthPlugin from '@fullcalendar/multimonth';
import allLocales from '@fullcalendar/core/locales-all';
import { renderStreamMessage } from '@hotwired/turbo';
import { TurboHelpers } from 'core-turbo/helpers';
import moment from 'moment';

interface NonWorkingDayEvent {
  date?:string;
  start?:string;
  end?:string;
  title:string;
  type:'global' | 'user';
  workingDays?:number;
  edit_url?:string;
}

export default class NonWorkingTimesController extends Controller {
  static targets = ['calendar'];

  static values = {
    events: Array,
    year: Number,
    locale: String,
    startOfWeek: Number,
    workingDays: Array,
    newUrl: String,
  };

  declare readonly calendarTarget:HTMLElement;
  declare readonly eventsValue:NonWorkingDayEvent[];
  declare readonly yearValue:number;
  declare readonly localeValue:string;
  declare readonly startOfWeekValue:number;
  declare readonly workingDaysValue:number[];
  declare readonly hasNewUrlValue:boolean;
  declare readonly newUrlValue:string;

  private calendar:Calendar;

  connect() {
    // Delay initialization to ensure the calendar container is fully rendered
    setTimeout(() => {
      this.initializeCalendar();
      this.scrollToToday();
    }, 5);
  }

  disconnect() {
    if (this.calendar) {
      this.calendar.destroy();
    }
  }

  initializeCalendar() {
    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [multiMonthPlugin, interactionPlugin],
      initialView: 'multiMonthYear',
      multiMonthMaxColumns: 1,
      locales: allLocales,
      locale: this.localeValue,
      firstDay: this.startOfWeekValue,
      initialDate: `${this.yearValue}-01-01`,
      headerToolbar: false,
      events: this.buildEvents(),
      nowIndicator: true,
      height: '100%',
      businessHours: {
        daysOfWeek: this.workingDaysValue,
        startTime: '00:00',
        endTime: '24:00',
      },
      eventClick: (info) => {
        const editUrl = info.event.extendedProps.editUrl as string | undefined;
        if (editUrl) {
          info.jsEvent.preventDefault();
          this.openDialog(editUrl);
        }
      },
      selectable: this.hasNewUrlValue,
      select: (info) => {
        const inclusiveEnd = moment(info.end).subtract(12, 'hours').toDate();
        const endStr = inclusiveEnd.toISOString().slice(0, 10);
        const url = `${this.newUrlValue}?start_date=${info.startStr}&end_date=${endStr}`;
        this.openDialog(url);
        this.calendar.unselect();
      },
    });

    this.calendar.render();
  }

  private openDialog(url:string):void {
    TurboHelpers.showProgressBar();

    void fetch(url, {
      headers: { Accept: 'text/vnd.turbo-stream.html' },
    })
      .then((response) => response.text())
      .then((html) => { renderStreamMessage(html); })
      .finally(() => { TurboHelpers.hideProgressBar(); });
  }

  private scrollToToday() {
    if (this.yearValue !== new Date().getFullYear()) return;

    this.calendarTarget
      .querySelector('.fc-day-today')
      ?.closest('.fc-multimonth-month')
      ?.scrollIntoView({ block: 'start' });
  }

  private buildEvents() {
    return this.eventsValue.map((event) => {
      if (event.type === 'global') {
        return {
          date: event.date,
          title: event.title,
          display: 'background',
          classNames: ['non-working-day--global'],
        };
      }

      return {
        start: event.start,
        end: event.end,
        title: event.title,
        extendedProps: { workingDays: event.workingDays, editUrl: event.edit_url },
        classNames: ['non-working-day--user'],
        allDay: true,
      };
    });
  }
}
