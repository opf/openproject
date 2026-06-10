import { ActionEvent, Controller } from '@hotwired/stimulus';
import { Calendar, EventApi, EventContentArg } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';
import momentTimezonePlugin from '@fullcalendar/moment-timezone';
import { toMoment } from '@fullcalendar/moment';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import moment from 'moment';
import allLocales from '@fullcalendar/core/locales-all';
import { renderStreamMessage } from '@hotwired/turbo';
import { opStopwatchStopIconData, toDOMString } from '@openproject/octicons-angular';
import { useMeta } from 'stimulus-use';
import { html, render, TemplateResult } from 'lit-html';
import { unsafeHTML } from 'lit-html/directives/unsafe-html.js';

export default class MyTimeTrackingController extends Controller {
  private turboRequests:TurboRequestsService;
  private pathHelper:PathHelperService;

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
  declare readonly timeEntriesValue:object[];
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

  async connect() {
    useMeta(this, { suffix: false });
    const context = await window.OpenProject.getPluginContext();
    this.turboRequests = context.services.turboRequests;
    this.pathHelper = context.services.pathHelperService;

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
          classes.push('calendar-time-entry-event-ongoing');
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
          `${this.pathHelper.timeEntryDialog()}?${dialogParams}`,
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
        // check if we clicked on a link tag, if so exit early as we don't want to show the modal
        if (info.jsEvent.target instanceof HTMLAnchorElement) {
          return;
        }

        void this.turboRequests.request(
          `${this.pathHelper.timeEntryEditDialog(info.event.id)}?onlyMe=true`,
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
    let timeDetails:string|TemplateResult = '';
    let stopTimerButton = '';
    let duration = info.event.extendedProps.hours as number;

    if (info.isResizing && info.event.start && info.event.end) {
      duration = this.calculateHours(info.event);
    }

    if (!info.event.allDay) {
      const time = `${toMoment(info.event.start!, this.calendar).format('LT')} - ${toMoment(info.event.end!, this.calendar).format('LT')}`;
      timeDetails = html`<div class="fc-event-times" title="${time}">${time}</div>`;
    }

    if (info.event.extendedProps.ongoing) {
      stopTimerButton = toDOMString(opStopwatchStopIconData, 'small', {
        'aria-hidden': 'true',
        class: 'octicon stop-timer-button',
      });
    }

    return html`
      <div class="fc-event-time">
        ${unsafeHTML(stopTimerButton)}
        ${this.displayDuration(duration)}
      </div>
      <div class="fc-event-title-container">
        <div class="fc-event-title fc-event-wp" title="${info.event.extendedProps.workPackageSubject}">
          <a class="Link--primary Link"
             href="${this.pathHelper.workPackageShortPath(info.event.extendedProps.workPackageId as string)}">
            ${info.event.extendedProps.workPackageSubject}
          </a>
        </div>
        <div class="fc-event-project" title="${info.event.extendedProps.projectName}">
          ${info.event.extendedProps.projectName}
        </div>
        ${timeDetails}
      </div>`;
  }

  addTotalFooter() {
    if (!this.calendar) return;
    const calendarScrollGridWrapper = document.querySelector('.fc-timegrid .fc-scrollgrid tbody');

    if (!calendarScrollGridWrapper) return;

    // Remove existing footer if it exists
    const existingFooter = document.querySelector('.fc-timegrid-footer-totals');
    if (existingFooter) { existingFooter.remove(); }

    const days:string[] = [];
    document
      .querySelectorAll('.fc-timegrid-cols .fc-day')
      .forEach((dayElement) => {
        days.push(dayElement.getAttribute('data-date')!);
      });

    calendarScrollGridWrapper.appendChild(this.buildHtmlFooter(days));
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

  buildHtmlFooter(days:string[]):HTMLTableRowElement {
    const tr = document.createElement('tr');
    tr.setAttribute('role', 'presentation');
    tr.className = 'fc-scrollgrid-section fc-timegrid-footer-totals';

    const td = document.createElement('td');
    td.setAttribute('role', 'presentation');

    const scrollerHarness = document.createElement('div');
    scrollerHarness.className = 'fc-scroller-harness';

    const scroller = document.createElement('div');
    scroller.className = 'fc-scroller';
    scroller.style.overflow = 'hidden scroll';

    const table = document.createElement('table');
    table.setAttribute('role', 'presentation');
    table.className = 'fc-col-footer';

    const colgroup = document.createElement('colgroup');
    const col = document.createElement('col');
    const otherCol = document.querySelector<HTMLTableColElement>('.fc-scrollgrid-section-header .fc-col-header col');
    if (otherCol) {
      col.style.width = otherCol.style.width;
    }

    const tbody = document.createElement('tbody');
    tbody.setAttribute('role', 'presentation');

    const tbodyTr = document.createElement('tr');
    tbodyTr.setAttribute('role', 'row');

    const th1 = document.createElement('th');
    th1.setAttribute('aria-hidden', 'true');
    th1.className = 'fc-timegrid-axis';

    const axisFrame = document.createElement('div');
    axisFrame.className = 'fc-timegrid-axis-frame';

    th1.appendChild(axisFrame);
    tbodyTr.appendChild(th1);

    // Add columns for each day
    days.forEach((day) => {
      const footerCell = document.createElement('th');
      footerCell.setAttribute('role', 'columnfooter');
      footerCell.className = 'fc-col-footer-cell fc-day';

      // Inner div in der zweiten Zelle erstellen
      const syncInner = document.createElement('div');
      syncInner.className = 'fc-scrollgrid-sync-inner';
      syncInner.textContent = this.displayDuration(
        this.calculateTotalHours(day),
      );
      footerCell.appendChild(syncInner);
      tbodyTr.appendChild(footerCell);
    });

    tbody.appendChild(tbodyTr);
    colgroup.appendChild(col);
    table.appendChild(colgroup);
    table.appendChild(tbody);
    scroller.appendChild(table);
    scrollerHarness.appendChild(scroller);
    td.appendChild(scrollerHarness);
    tr.appendChild(td);

    return tr;
  }

  updateTimeEntry(timeEntryId:string, spentOn:string, startTime:string|null, hours:number, revertFunction:() => void) {
    fetch(this.pathHelper.timeEntryUpdate(timeEntryId), {
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

  displayDuration(duration:number):string {
    const hours = Math.floor(duration);
    const minutes = Math.round((duration - hours) * 60);

    if (minutes === 0) {
      return `${hours}h`;
    }
    if (hours === 0) {
      return `${minutes}m`;
    }
    return `${hours}h ${minutes}m`;
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

  newTimeEntry(event:ActionEvent) {
    const dialogParams = `onlyMe=true&date=${event.params.date}`;

    void this.turboRequests.request(
      `${this.pathHelper.timeEntryDialog()}?${dialogParams}`,
      { method: 'GET' },
    );
  }

  dialogCloseListener(event:CustomEvent):void {
    interface AdditionalDialogCloseData {
      spent_on?:string;
    }

    const { detail: { dialog, additional, submitted } } = event as {
      detail:{ dialog:HTMLDialogElement; additional:AdditionalDialogCloseData|undefined; submitted:boolean }
    };
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
        void this.turboRequests.request(this.pathHelper.myTimeTrackingRefresh(additional.spent_on, this.viewModeValue, this.modeValue), { method: 'GET' });
      } else {
        window.location.reload();
      }
    }
  }
}
