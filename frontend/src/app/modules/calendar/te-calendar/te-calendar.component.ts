import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Injector,
  Input,
  OnInit,
  Output,
  SecurityContext,
  ViewChild,
  ViewEncapsulation
} from "@angular/core";
import {FullCalendarComponent} from '@fullcalendar/angular';
import {States} from "core-components/states.service";
import * as moment from "moment";
import {Moment} from "moment";
import {StateService} from "@uirouter/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {DomSanitizer} from "@angular/platform-browser";
import timeGrid from '@fullcalendar/timegrid';
import {Duration, EventApi, EventInput, View} from '@fullcalendar/core';
import {EventSourceError} from '@fullcalendar/core/structs/event-source';
import {ToolbarInput} from '@fullcalendar/core/types/input-types';
import {ConfigurationService} from "core-app/modules/common/config/configuration.service";
import {TimeEntryDmService} from "core-app/modules/hal/dm-services/time-entry-dm.service";
import {FilterOperator} from "core-components/api/api-v3/api-v3-filter-builder";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {TimeEntryCacheService} from "core-components/time-entries/time-entry-cache.service";
import interactionPlugin from '@fullcalendar/interaction';
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {TimeEntryEditService} from "core-app/modules/time_entries/edit/edit.service";
import {TimeEntryCreateService} from "core-app/modules/time_entries/create/create.service";
import {ColorsService} from "core-app/modules/common/colors/colors.service";
import {BrowserDetector} from "core-app/modules/common/browser/browser-detector.service";
import {HalResourceNotificationService} from 'core-app/modules/hal/services/hal-resource-notification.service';

interface CalendarViewEvent {
  el:HTMLElement;
  event:EventApi;
  jsEvent:MouseEvent;
}

interface CalendarMoveEvent {
  el:HTMLElement;
  event:EventApi;
  oldEvent:EventApi;
  delta:Duration;
  revert:() => void;
  jsEvent:Event;
  view:View;
}

// An array of all the days that are displayed. The zero index represents Monday.
export type DisplayedDays = [boolean, boolean, boolean, boolean, boolean, boolean, boolean];

const TIME_ENTRY_CLASS_NAME = 'te-calendar--time-entry';
const DAY_SUM_CLASS_NAME = 'te-calendar--day-sum';
const ADD_ENTRY_CLASS_NAME = 'te-calendar--add-entry';
const ADD_ICON_CLASS_NAME = 'te-calendar--add-icon';
const ADD_ENTRY_PROHIBITED_CLASS_NAME = '-prohibited';

@Component({
  templateUrl: './te-calendar.template.html',
  styleUrls: ['./te-calendar.component.sass'],
  selector: 'te-calendar',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    TimeEntryEditService,
    TimeEntryCreateService,
    HalResourceEditingService
  ]
})
export class TimeEntryCalendarComponent implements OnInit, AfterViewInit {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;
  @Input() projectIdentifier:string;
  @Input() static:boolean = false;
  @Input() set displayedDays(days:DisplayedDays) {
    this.setHiddenDays(days);
  }
  @Output() entries = new EventEmitter<CollectionResource<TimeEntryResource>>();

  // Not used by the calendar but rather is the maximum/minimum of the graph.
  public minHour = 1;
  public maxHour = 12;
  public labelIntervalHours = 2;
  public scaleRatio = 1;

  public calendarPlugins = [timeGrid, interactionPlugin];
  public calendarEvents:Function;
  public calendarHeader:ToolbarInput|boolean = {
    right: '',
    center: 'title',
    left: 'prev,next today'
  };
  public calendarSlotLabelFormat = (info:any) => (this.maxHour - info.date.hour) / this.scaleRatio;
  public calendarSlotLabelInterval = `${this.labelIntervalHours}:00:00`;
  public calendarContentHeight = 605;
  public calendarAllDaySlot = false;
  public calendarDisplayEventTime = false;
  public calendarSlotEventOverlap = false;
  public calendarEditable = false;
  public calendarMinTime = `${this.minHour - 1}:00:00`;
  public calendarMaxTime = `${this.maxHour}:00:00`;
  public calendarEventOverlap = (stillEvent:any) => !stillEvent.classNames.includes(TIME_ENTRY_CLASS_NAME);

  protected memoizedTimeEntries:{ start:Date, end:Date, entries:Promise<CollectionResource<TimeEntryResource>> };
  public memoizedCreateAllowed:boolean = false;
  public hiddenDays:number[] = [];

  public text = {
    logTime: this.i18n.t('js.button_log_time')
  };

  constructor(readonly states:States,
              readonly timeEntryDm:TimeEntryDmService,
              readonly $state:StateService,
              private element:ElementRef,
              readonly i18n:I18nService,
              readonly injector:Injector,
              readonly notifications:HalResourceNotificationService,
              private sanitizer:DomSanitizer,
              private configuration:ConfigurationService,
              private timezone:TimezoneService,
              private timeEntryEdit:TimeEntryEditService,
              private timeEntryCreate:TimeEntryCreateService,
              private timeEntryCache:TimeEntryCacheService,
              private colors:ColorsService,
              private browserDetector:BrowserDetector) {
  }

  ngOnInit() {
    this.initializeCalendar();
  }

  ngAfterViewInit() {
    // The full-calendar component's outputs do not seem to work
    // see: https://github.com/fullcalendar/fullcalendar-angular/issues/228#issuecomment-523505044
    // Therefore, setting the outputs via the underlying API
    this.ucCalendar.getApi().setOption('eventRender', (event:CalendarViewEvent) => {
      this.alterEventEntry(event);
    });
    this.ucCalendar.getApi().setOption('eventDestroy', (event:CalendarViewEvent) => {
      this.beforeEventRemove(event);
    });
    this.ucCalendar.getApi().setOption('eventClick', (event:CalendarViewEvent) => {
      this.dispatchEventClick(event);
    });
    this.ucCalendar.getApi().setOption('eventDrop', (event:CalendarMoveEvent) => {
      this.moveEvent(event);
    });
  }

  public calendarEventsFunction(fetchInfo:{ start:Date, end:Date },
                                successCallback:(events:EventInput[]) => void,
                                failureCallback:(error:EventSourceError) => void):void|PromiseLike<EventInput[]> {

    this.fetchTimeEntries(fetchInfo.start, fetchInfo.end)
      .then((collection) => {
        this.entries.emit(collection);

        successCallback(this.buildEntries(collection.elements, fetchInfo));
      });
  }

  protected fetchTimeEntries(start:Date, end:Date) {
    if (!this.memoizedTimeEntries ||
      this.memoizedTimeEntries.start.getTime() !== start.getTime() ||
      this.memoizedTimeEntries.end.getTime() !== end.getTime()) {
      let promise = this
        .timeEntryDm
        .list({ filters: this.dmFilters(start, end), pageSize: 500 })
        .then(collection => {
          this.memoizedCreateAllowed = !!collection.createTimeEntry;

          collection.elements.forEach(timeEntry => this.timeEntryCache.updateValue(timeEntry.id!, timeEntry));

          return collection;
        });

      this.memoizedTimeEntries = { start: start, end: end, entries: promise };
    }

    return this.memoizedTimeEntries.entries;
  }

  private buildEntries(entries:TimeEntryResource[], fetchInfo:{ start:Date, end:Date }) {
    this.setRatio(entries);

    return this.buildTimeEntryEntries(entries)
      .concat(this.buildAuxEntries(entries, fetchInfo));
  }

  private setRatio(entries:TimeEntryResource[]) {
    let dateSums = this.calculateDateSums(entries);

    let maxHours = Math.max(...Object.values(dateSums), 0);

    let oldRatio = this.scaleRatio;

    if (maxHours > this.maxHour - this.minHour) {
      this.scaleRatio = this.smallerSuitableRatio((this.maxHour - this.minHour) / maxHours);
    } else {
      this.scaleRatio = 1;
    }

    if (oldRatio !== this.scaleRatio) {
      // This is a hack.
      // We already set the same function (different object) via angular.
      // But it will trigger repainting the calendar.
      // Weirdly, this.ucCalendar.getApi().rerender() does not.
      this.ucCalendar.getApi().setOption('slotLabelFormat', (info:any) => {
        return (this.maxHour - info.date.hour) / this.scaleRatio;
      });
    }
  }

  private buildTimeEntryEntries(entries:TimeEntryResource[]) {
    let hoursDistribution:{ [key:string]:Moment } = {};

    return entries.map((entry) => {
      let start:Moment;
      let end:Moment;
      let hours = this.timezone.toHours(entry.hours) * this.scaleRatio;

      if (hoursDistribution[entry.spentOn]) {
        start = hoursDistribution[entry.spentOn].clone().subtract(hours, 'h');
        end = hoursDistribution[entry.spentOn].clone();
      } else {
        start = moment(entry.spentOn).add(this.maxHour - hours, 'h');
        end = moment(entry.spentOn).add(this.maxHour, 'h');
      }

      hoursDistribution[entry.spentOn] = start;

      const color = this.colors.toHsl(this.entryName(entry));

      return this.timeEntry(entry, hours, start, end);
    }) as EventInput[];
  }

  private buildAuxEntries(entries:TimeEntryResource[], fetchInfo:{ start:Date, end:Date }) {
    let dateSums = this.calculateDateSums(entries);

    let calendarEntries:EventInput[] = [];

    for (let m = moment(fetchInfo.start); m.diff(fetchInfo.end, 'days') <= 0; m.add(1, 'days')) {
      let duration = dateSums[m.format('YYYY-MM-DD')] || 0;

      calendarEntries.push(this.sumEntry(m, duration));

      if (this.memoizedCreateAllowed) {
        calendarEntries.push(this.addEntry(m, duration));
      }
    }

    return calendarEntries;
  }

  private calculateDateSums(entries:TimeEntryResource[]) {
    let dateSums:{ [key:string]:number } = {};

    entries.forEach((entry) => {
      let hours = this.timezone.toHours(entry.hours);

      if (dateSums[entry.spentOn]) {
        dateSums[entry.spentOn] += hours;
      } else {
        dateSums[entry.spentOn] = hours;
      }
    });

    return dateSums;
  }

  protected timeEntry(entry:TimeEntryResource, hours:number, start:Moment, end:Moment) {
    const color = this.colors.toHsl(this.entryName(entry));

    let classNames = [TIME_ENTRY_CLASS_NAME];

    let span = end.diff(start, 'm');

    if (span < 40) {
      classNames.push('-no-fadeout');
    }

    return {
      title: span < 20 ? '' : this.entryName(entry),
      startEditable: !!entry.update,
      start: start.format(),
      end: end.format(),
      backgroundColor: color,
      borderColor: color,
      classNames: classNames,
      entry: entry
    };
  }

  protected sumEntry(date:Moment, duration:number) {
    return {
      start: date.clone().add(this.maxHour - Math.min(duration * this.scaleRatio, this.maxHour - 0.5) - 0.5, 'h').format(),
      end: date.clone().add(this.maxHour - Math.min(((duration + 0.05) * this.scaleRatio), this.maxHour - 0.5), 'h').format(),
      classNames: DAY_SUM_CLASS_NAME,
      rendering: 'background' as 'background',
      sum: this.i18n.t('js.units.hour', { count: this.formatNumber(duration) })
    };
  }

  protected addEntry(date:Moment, duration:number) {
    let classNames = [ADD_ENTRY_CLASS_NAME];

    if (duration >= 24) {
      classNames.push(ADD_ENTRY_PROHIBITED_CLASS_NAME);
    }

    return {
      start: date.clone().format(),
      end: date.clone().add(this.maxHour - Math.min(duration * this.scaleRatio, this.maxHour - 1) - 0.5, 'h').format(),
      rendering: "background" as 'background',
      classNames: classNames
    };
  }

  protected dmFilters(start:Date, end:Date):Array<[string, FilterOperator, string[]]> {
    let startDate = moment(start).format('YYYY-MM-DD');
    let endDate = moment(end).subtract(1, 'd').format('YYYY-MM-DD');
    return [['spentOn', '<>d', [startDate, endDate]] as [string, FilterOperator, string[]],
      ['user_id', '=', ['me']] as [string, FilterOperator, [string]]];
  }

  private initializeCalendar() {
    this.calendarEvents = this.calendarEventsFunction.bind(this);
  }

  public get calendarEventLimit() {
    return false;
  }

  public get calendarLocale() {
    return this.i18n.locale;
  }

  public get calendarFixedWeekCount() {
    return false;
  }

  public get calendarDefaultView() {
    return 'timeGridWeek';
  }

  public get calendarFirstDay() {
    return this.configuration.startOfWeek();
  }

  private get calendarElement() {
    return jQuery(this.element.nativeElement).find('.fc-view-container');
  }

  private dispatchEventClick(event:CalendarViewEvent) {
    if (event.event.extendedProps.entry) {
      this.editEvent(event.event.extendedProps.entry);
    } else if (event.el.classList.contains(ADD_ENTRY_CLASS_NAME) && !event.el.classList.contains(ADD_ENTRY_PROHIBITED_CLASS_NAME)) {
      this.addEvent(moment(event.event.start!));
    }
  }

  private editEvent(entry:TimeEntryResource) {
    this
      .timeEntryEdit
      .edit(entry)
      .then(modificationAction => {
        this.updateEventSet(modificationAction.entry, modificationAction.action);
      })
      .catch(() => {
        // do nothing, the user closed without changes
      });
  }

  private moveEvent(event:CalendarMoveEvent) {
    let entry = event.event.extendedProps.entry;

    // Use end instead of start as when dragging, the event might be too long and would thus be start
    // on the day before by fullcalendar.
    entry.spentOn = moment(event.event.end!).format('YYYY-MM-DD');

    this
      .timeEntryDm
      .update(entry, entry.schema)
      .then(event => {
        this.updateEventSet(event, 'update');
      })
      .catch((e) => {
        this.notifications.handleRawError(e);
        event.revert();
      });
  }

  public addEventToday() {
    this.addEvent(moment(new Date()));
  }

  private addEvent(date:Moment) {
    if (!this.memoizedCreateAllowed) {
      return;
    }

    this
      .timeEntryCreate
      .create(date)
      .then(modificationAction => {
        this.updateEventSet(modificationAction.entry, modificationAction.action);
      })
      .catch(() => {
        // do nothing, the user closed without changes
      });
  }

  private updateEventSet(event:TimeEntryResource, action:'update'|'destroy'|'create') {
    this.memoizedTimeEntries.entries.then(collection => {
      let foundIndex = collection.elements.findIndex(x => x.id === event.id);

      switch (action) {
        case 'update':
          collection.elements[foundIndex] = event;
          break;
        case 'destroy':
          collection.elements.splice(foundIndex, 1);
          break;
        case 'create':
          this.timeEntryCache.updateValue(event.id!, event);
          collection.elements.push(event);
          break;
      }

      this.ucCalendar.getApi().refetchEvents();
    });
  }

  private alterEventEntry(event:CalendarViewEvent) {
    this.appendAddIcon(event);
    this.appendSum(event);

    if (!event.event.extendedProps.entry) {
      return;
    }

    this.addTooltip(event);
    this.prependDuration(event);
    this.appendFadeout(event);
  }

  private appendAddIcon(event:CalendarViewEvent) {
    if (!event.el.classList.contains(ADD_ENTRY_CLASS_NAME)) {
      return;
    }

    let addIcon = document.createElement('div');
    addIcon.classList.add(ADD_ICON_CLASS_NAME);
    addIcon.innerText = '+';
    event.el.append(addIcon);
  }

  private appendSum(event:CalendarViewEvent) {
    if (event.event.extendedProps.sum) {
      event.el.append(event.event.extendedProps.sum);
    }
  }

  private addTooltip(event:CalendarViewEvent) {
    if (this.browserDetector.isMobile) {
      return;
    }

    jQuery(event.el).tooltip({
      content: this.tooltipContentString(event.event.extendedProps.entry),
      items: '.fc-event',
      close: function () {
        jQuery(".ui-helper-hidden-accessible").remove();
      },
      track: true
    });
  }

  private removeTooltip(event:CalendarViewEvent) {
    jQuery(event.el).tooltip('disable');
  }

  private prependDuration(event:CalendarViewEvent) {
    let formattedDuration = this.timezone.formattedDuration(event.event.extendedProps.entry.hours);

    jQuery(event.el)
      .find('.fc-title')
      .prepend(`<div class="fc-duration">${formattedDuration}</div>`);
  }

  /* Fade out event text to the bottom to avoid it being cut of weirdly.
  * Multiline ellipsis with an unknown height is not possible, hence we blur the text.
  * The gradient needs to take the background color of the element into account (hashed over the event
  * title) which is why the style is set in code.
  *
  * We do not print anything on short entries (< 0.5 hours),
  * which leads to the fc-short class not being applied by full calendar. For other short events, the css rules
  * need to deactivate the fc-fadeout.
   */
  private appendFadeout(event:CalendarViewEvent) {
    let timeEntry = event.event.extendedProps.entry;

    if (this.timezone.toHours(timeEntry.hours) < 0.5) {
      return;
    }

    let $element = jQuery(event.el);
    let fadeout = jQuery(`<div class="fc-fadeout"></div>`);

    let hslaStart = this.colors.toHsla(this.entryName(timeEntry), 0);
    let hslaEnd = this.colors.toHsla(this.entryName(timeEntry), 100);

    fadeout.css('background', `-webkit-linear-gradient(${hslaStart} 0%, ${hslaEnd} 100%`);

    ['-moz-linear-gradient', '-o-linear-gradient', 'linear-gradient', '-ms-linear-gradient'].forEach((style => {
      fadeout.css('background-image', `${style}(${hslaStart} 0%, ${hslaEnd} 100%`);
    }));

    $element
      .append(fadeout);
  }

  private beforeEventRemove(event:CalendarViewEvent) {
    if (!event.event.extendedProps.entry) {
      return;
    }

    this.removeTooltip(event);
  }

  private entryName(entry:TimeEntryResource) {
    let name = entry.project.name;
    if (entry.workPackage) {
      name += ` - ${this.workPackageName(entry)}`;
    }

    return name || '-';
  }

  private workPackageName(entry:TimeEntryResource) {
    return `#${entry.workPackage.idFromLink}: ${entry.workPackage.name}`;
  }

  private tooltipContentString(entry:TimeEntryResource) {
    return `
        <ul class="tooltip--map">
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.time_entry.project')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(entry.project.name)}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.time_entry.work_package')}:</span>
            <span class="tooltip--map--value">${entry.workPackage ? this.sanitizedValue(this.workPackageName(entry)) : this.i18n.t('js.placeholders.default')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.time_entry.activity')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(entry.activity.name)}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.time_entry.hours')}:</span>
            <span class="tooltip--map--value">${this.timezone.formattedDuration(entry.hours)}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.time_entry.comment')}:</span>
            <span class="tooltip--map--value">${entry.comment.raw || this.i18n.t('js.placeholders.default')}</span>
          </li>
        `;
  }

  private sanitizedValue(value:string) {
    return this.sanitizer.sanitize(SecurityContext.HTML, value);
  }

  protected formatNumber(value:number):string {
    return this.i18n.toNumber(value, { precision: 2 });
  }

  private smallerSuitableRatio(value:number):number {
    for (let divisor = this.labelIntervalHours + 1; divisor < 100; divisor++) {
      let candidate = this.labelIntervalHours / divisor;

      if (value >= candidate) {
        return candidate;
      }
    }

    return 1;
  }

  protected setHiddenDays(displayedDays:DisplayedDays) {
    this.hiddenDays = Array.from(displayedDays, (value, index) => {
      if (!value) {
        return (index + 1) % 7;
      } else {
        return null;
      }
    }).filter((value) => value !== null) as number[];
  }
}
