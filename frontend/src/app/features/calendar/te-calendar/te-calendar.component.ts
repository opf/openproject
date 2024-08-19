import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Injector,
  Input,
  Output,
  SecurityContext,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { FullCalendarComponent } from '@fullcalendar/angular';
import { States } from 'core-app/core/states/states.service';
import * as moment from 'moment';
import { Moment } from 'moment';
import { StateService } from '@uirouter/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DomSanitizer } from '@angular/platform-browser';
import timeGrid from '@fullcalendar/timegrid';
import {
  CalendarOptions,
  DayCellContentArg,
  DayCellMountArg,
  DayHeaderContentArg,
  Duration,
  EventApi,
  EventInput,
  EventSourceFuncArg,
  SlotLabelContentArg,
  SlotLaneContentArg,
} from '@fullcalendar/core';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import interactionPlugin from '@fullcalendar/interaction';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { TimeEntryEditService } from 'core-app/shared/components/time_entries/edit/edit.service';
import { TimeEntryCreateService } from 'core-app/shared/components/time_entries/create/create.service';
import { ColorsService } from 'core-app/shared/components/colors/colors.service';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { VerboseFormattingArg } from '@fullcalendar/common';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { firstValueFrom, Subject } from 'rxjs';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import allLocales from '@fullcalendar/core/locales-all';

interface TimeEntrySchema extends SchemaResource {
  activity:IFieldSchema;
  workPackage:IFieldSchema;
  project:IFieldSchema;
  hours:IFieldSchema;
  user:IFieldSchema;
  comment:IFieldSchema;
}

interface CalendarViewEvent {
  el:HTMLElement;
  event:EventApi;
}

interface CalendarMoveEvent {
  el:HTMLElement;
  event:EventApi;
  oldEvent:EventApi;
  delta:Duration;
  revert:() => void;
}
interface CalendarOptionsWithDayGrid extends CalendarOptions {
  dayGridClassNames:(data:DayCellMountArg) => void;
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
  selector: 'op-time-entries-calendar',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    OpCalendarService,
    TimeEntryEditService,
    TimeEntryCreateService,
    HalResourceEditingService,
  ],
})
export class TimeEntryCalendarComponent {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @Input() projectIdentifier:string;

  @Input() static = false;

  @Input() set displayedDays(days:DisplayedDays) {
    this.initializeCalendar(days);
  }

  @Output() entries = new EventEmitter<CollectionResource<TimeEntryResource>>();

  // Not used by the calendar but rather is the maximum/minimum of the graph.
  public minHour = 1;

  public maxHour = 12;

  public labelIntervalHours = 2;

  public scaleRatio = 1;

  protected memoizedTimeEntries:{ start:Moment, end:Moment, entries:Promise<CollectionResource<TimeEntryResource>> };

  public memoizedCreateAllowed = false;

  public text = {
    logTime: this.i18n.t('js.button_log_time'),
    today: this.i18n.t('js.team_planner.today'),
  };

  calendarOptions$ = new Subject<CalendarOptions>();

  public nonWorkingDays:IDay[] = [];

  public additionalOptions:CalendarOptionsWithDayGrid = {
    editable: false,
    locales: allLocales,
    locale: this.i18n.locale,
    fixedWeekCount: false,
    headerToolbar: {
      right: '',
      center: 'title',
      left: 'prev,next today',
    },
    buttonText: { today: this.text.today },
    initialView: 'timeGridWeek',
    firstDay: this.configuration.startOfWeek(),
    timeZone: this.configuration.isTimezoneSet() ? this.configuration.timezone() : 'local',
    hiddenDays: [],
    // This is a magic number that is derived by trial and error
    contentHeight: 550,
    slotEventOverlap: false,
    slotLabelInterval: `${this.labelIntervalHours}:00:00`,
    slotLabelFormat: (info:VerboseFormattingArg) => ((this.maxHour - info.date.hour) / this.scaleRatio).toString(),
    allDaySlot: false,
    displayEventTime: false,
    slotMinTime: `${this.minHour - 1}:00:00`,
    slotMaxTime: `${this.maxHour}:00:00`,
    events: this.calendarEventsFunction.bind(this),
    eventOverlap: (stillEvent:EventApi) => !stillEvent.classNames.includes(TIME_ENTRY_CLASS_NAME),
    plugins: [timeGrid, interactionPlugin],
    eventDidMount: this.alterEventEntry.bind(this),
    eventWillUnmount: this.beforeEventRemove.bind(this),
    eventClick: this.dispatchEventClick.bind(this),
    eventDrop: this.moveEvent.bind(this),
    dayHeaderClassNames: (data:DayHeaderContentArg) => this.calendar.applyNonWorkingDay(data, this.nonWorkingDays),
    dayCellClassNames: (data:DayCellContentArg) => this.calendar.applyNonWorkingDay(data, this.nonWorkingDays),
    dayGridClassNames: (data:DayCellContentArg) => this.calendar.applyNonWorkingDay(data, this.nonWorkingDays),
    slotLaneClassNames: (data:SlotLaneContentArg) => this.calendar.applyNonWorkingDay(data, this.nonWorkingDays),
    slotLabelClassNames: (data:SlotLabelContentArg) => this.calendar.applyNonWorkingDay(data, this.nonWorkingDays),
  };

  private initializeCalendar(displayedDayss:DisplayedDays) {
    void this.weekdayService.loadWeekdays()
      .toPromise()
      .then(async () => {
        const date = moment(new Date()).toString();
        await this.requireNonWorkingDays(date);
        this.additionalOptions.hiddenDays = this.setHiddenDays(displayedDayss);
        this.calendarOptions$.next(
          this.additionalOptions,
        );
      });
  }

  constructor(
    readonly states:States,
    readonly apiV3Service:ApiV3Service,
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
    private schemaCache:SchemaCacheService,
    private colors:ColorsService,
    private browserDetector:BrowserDetector,
    private calendar:OpCalendarService,
    readonly weekdayService:WeekdayService,
    readonly dayService:DayResourceService,
  ) {}

  async requireNonWorkingDays(date:Date|string) {
    this.nonWorkingDays = await firstValueFrom(this.dayService.requireNonWorkingYear$(date));
  }

  public calendarEventsFunction(
    fetchInfo:EventSourceFuncArg,
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:Error) => void,
  ):void|PromiseLike<EventInput[]> {
    const start = moment(fetchInfo.startStr);
    const end = moment(fetchInfo.endStr);
    void this.fetchTimeEntries(start, end)
      .then(async (collection) => {
        this.entries.emit(collection);

        successCallback(await this.buildEntries(collection.elements, fetchInfo));
      })
      .catch(failureCallback);
  }

  protected fetchTimeEntries(start:Moment, end:Moment):Promise<CollectionResource<TimeEntryResource>> {
    if (!this.memoizedTimeEntries
      || this.memoizedTimeEntries.start.valueOf() !== start.valueOf()
      || this.memoizedTimeEntries.end.valueOf() !== end.valueOf()) {
      const promise = firstValueFrom(
        this
          .apiV3Service
          .time_entries
          .list({ filters: this.dmFilters(start, end), pageSize: 500 }),
      )
        .then((collection) => {
          this.memoizedCreateAllowed = !!collection.createTimeEntry;

          return collection;
        });

      this.memoizedTimeEntries = { start, end, entries: promise };
    }

    return this.memoizedTimeEntries.entries;
  }

  private async buildEntries(entries:TimeEntryResource[], fetchInfo:{ start:Date, end:Date }):Promise<EventInput[]> {
    this.setRatio(entries);
    await this.requireNonWorkingDays(fetchInfo.start);
    await this.requireNonWorkingDays(fetchInfo.end);
    return this.buildTimeEntryEntries(entries)
      .concat(this.buildAuxEntries(entries, fetchInfo));
  }

  private setRatio(entries:TimeEntryResource[]):void {
    const dateSums = this.calculateDateSums(entries);

    const maxHours = Math.max(...Object.values(dateSums), 0);

    const oldRatio = this.scaleRatio;

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
      this.ucCalendar.getApi().setOption('slotLabelFormat', (info:VerboseFormattingArg) => {
        const val = (this.maxHour - info.date.hour) / this.scaleRatio;
        return val.toString();
      });
    }
  }

  private buildTimeEntryEntries(entries:TimeEntryResource[]):EventInput[] {
    const hoursDistribution:{ [key:string]:Moment } = {};

    return entries.map((entry) => {
      let start:Moment;
      let end:Moment;
      const hours = this.timezone.toHours(entry.hours) * this.scaleRatio;
      const spentOn = entry.spentOn as string;

      if (hoursDistribution[spentOn]) {
        start = hoursDistribution[spentOn].clone().subtract(hours, 'h');
        end = hoursDistribution[spentOn].clone();
      } else {
        start = moment(spentOn).add(this.maxHour - hours, 'h');
        end = moment(spentOn).add(this.maxHour, 'h');
      }

      hoursDistribution[spentOn] = start;

      return this.timeEntry(entry, hours, start, end);
    });
  }

  private buildAuxEntries(entries:TimeEntryResource[], fetchInfo:{ start:Date, end:Date }):EventInput[] {
    const dateSums = this.calculateDateSums(entries);

    const calendarEntries:EventInput[] = [];

    for (let m = moment(this.timezone.formattedISODate(fetchInfo.start)); m.diff(fetchInfo.end, 'days') <= 0; m.add(1, 'days')) {
      const duration = dateSums[m.format('YYYY-MM-DD')] || 0;

      calendarEntries.push(this.sumEntry(m, duration));

      if (this.memoizedCreateAllowed) {
        calendarEntries.push(this.addEntry(m, duration));
      }
    }

    return calendarEntries;
  }

  private calculateDateSums(entries:TimeEntryResource[]):{ [p:string]:number } {
    const dateSums:{ [key:string]:number } = {};

    entries.forEach((entry) => {
      const hours = this.timezone.toHours(entry.hours);
      const spentOn = entry.spentOn as string;

      if (dateSums[spentOn]) {
        dateSums[spentOn] += hours;
      } else {
        dateSums[spentOn] = hours;
      }
    });

    return dateSums;
  }

  protected timeEntry(entry:TimeEntryResource, hours:number, start:Moment, end:Moment):EventInput {
    const color = this.colors.toHsl(this.entryName(entry));

    const classNames = [TIME_ENTRY_CLASS_NAME];

    const span = end.diff(start, 'm');

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
      classNames,
      entry,
    };
  }

  protected sumEntry(date:Moment, duration:number):EventInput {
    return {
      start: date.clone().add(this.maxHour - Math.min(duration * this.scaleRatio, this.maxHour - 0.5) - 0.5, 'h').format(),
      end: date.clone().add(this.maxHour - Math.min(((duration + 0.05) * this.scaleRatio), this.maxHour - 0.5), 'h').format(),
      classNames: DAY_SUM_CLASS_NAME,
      rendering: 'background' as const,
      startEditable: false,
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      sum: this.i18n.t('js.units.hour', { count: duration }),
    };
  }

  protected addEntry(date:Moment, duration:number):EventInput {
    const classNames = [ADD_ENTRY_CLASS_NAME];

    if (duration >= 24) {
      classNames.push(ADD_ENTRY_PROHIBITED_CLASS_NAME);
    }

    return {
      start: date.clone().format(),
      end: date.clone().add(this.maxHour - Math.min(duration * this.scaleRatio, this.maxHour - 1) - 0.5, 'h').format(),
      rendering: 'background' as const,
      classNames,
    };
  }

  protected dmFilters(start:Moment, end:Moment):Array<[string, FilterOperator, string[]]> {
    const startDate = start.format('YYYY-MM-DD');
    const endDate = end.subtract(1, 'd').format('YYYY-MM-DD');
    return [['spentOn', '<>d', [startDate, endDate]] as [string, FilterOperator, string[]],
      ['user_id', '=', ['me']] as [string, FilterOperator, [string]]];
  }

  private dispatchEventClick(event:CalendarViewEvent):void {
    if (event.event.extendedProps.entry) {
      this.editEvent(event.event.extendedProps.entry);
    } else if (event.el.classList.contains(ADD_ENTRY_CLASS_NAME) && !event.el.classList.contains(ADD_ENTRY_PROHIBITED_CLASS_NAME)) {
      this.addEvent(moment(event.event.startStr));
    }
  }

  private editEvent(entry:TimeEntryResource):void {
    this
      .timeEntryEdit
      .edit(entry, { showUserField: false })
      .then((modificationAction) => {
        this.updateEventSet(modificationAction.entry, modificationAction.action);
      })
      .catch(() => {
        // do nothing, the user closed without changes
      });
  }

  private moveEvent(event:CalendarMoveEvent):void {
    const entry = event.event.extendedProps.entry as TimeEntryResource;

    // Use end instead of start as when dragging, the event might be too long and would thus be start
    // on the day before by fullcalendar.
    entry.spentOn = moment(event.event.endStr).format('YYYY-MM-DD');

    void this
      .schemaCache
      .ensureLoaded(entry)
      .then((schema) => {
        this
          .apiV3Service
          .time_entries
          .id(entry)
          .patch(entry, schema)
          .subscribe(
            (updated) => this.updateEventSet(updated, 'update'),
            (e) => {
              this.notifications.handleRawError(e);
              event.revert();
            },
          );
      });
  }

  public addEventToday():void {
    this.addEvent(moment(new Date()));
  }

  private addEvent(date:Moment):void {
    if (!this.memoizedCreateAllowed) {
      return;
    }

    this
      .timeEntryCreate
      .create(date, undefined, { showUserField: false })
      .then((modificationAction) => {
        this.updateEventSet(modificationAction.entry, modificationAction.action);
      })
      .catch(() => {
        // do nothing, the user closed without changes
      });
  }

  private updateEventSet(event:TimeEntryResource, action:'update'|'destroy'|'create'|'unchanged'):void {
    void this.memoizedTimeEntries.entries.then((collection) => {
      const foundIndex = collection.elements.findIndex((x) => x.id === event.id);

      switch (action) {
        case 'update':
        case 'unchanged':
          collection.elements[foundIndex] = event;
          break;
        case 'destroy':
          collection.elements.splice(foundIndex, 1);
          break;
        case 'create':
          void this
            .apiV3Service
            .time_entries
            .cache
            .updateFor(event);

          collection.elements.push(event);
          break;
        default:
          throw new Error('Invalid action');
      }

      this.ucCalendar.getApi().refetchEvents();
    });
  }

  private alterEventEntry(event:CalendarViewEvent):void {
    this.appendAddIcon(event);
    this.appendSum(event);

    if (!event.event.extendedProps.entry) {
      return;
    }

    void this.addTooltip(event);
    this.prependDuration(event);
    this.appendFadeout(event);
  }

  private appendAddIcon(event:CalendarViewEvent):void {
    if (!event.el.classList.contains(ADD_ENTRY_CLASS_NAME)) {
      return;
    }

    const addIcon = document.createElement('div');
    addIcon.classList.add(ADD_ICON_CLASS_NAME);
    addIcon.innerText = '+';
    event.el.append(addIcon);
  }

  private appendSum(event:CalendarViewEvent):void {
    if (event.event.extendedProps.sum) {
      event.el.innerHTML = event.event.extendedProps.sum as string;
    }
  }

  private async addTooltip(event:CalendarViewEvent):Promise<void> {
    if (this.browserDetector.isMobile) {
      return;
    }

    const { entry } = event.event.extendedProps;

    const schema = await this.schemaCache.ensureLoaded(entry as TimeEntryResource) as TimeEntrySchema;

    jQuery(event.el).tooltip({
      content: this.tooltipContentString(event.event.extendedProps.entry, schema),
      items: '.fc-event',
      close() {
        jQuery('.ui-helper-hidden-accessible').remove();
      },
      track: true,
    });
  }

  private removeTooltip(event:CalendarViewEvent):void {
    const target = jQuery(event.el);

    if (target.tooltip('instance')) {
      jQuery(event.el).tooltip('disable');
    }
  }

  private prependDuration(event:CalendarViewEvent):void {
    const timeEntry = event.event.extendedProps.entry as TimeEntryResource;

    if (this.timezone.toHours(timeEntry.hours) < 0.5) {
      return;
    }

    const formattedDuration = this.timezone.formattedDuration(timeEntry.hours);

    jQuery(event.el)
      .find('.fc-event-title')
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
  private appendFadeout(event:CalendarViewEvent):void {
    const timeEntry = event.event.extendedProps.entry as TimeEntryResource;

    if (this.timezone.toHours(timeEntry.hours) < 0.5) {
      return;
    }

    const $element = jQuery(event.el);
    const fadeout = jQuery('<div class="fc-fadeout"></div>');

    const hslaStart = this.colors.toHsla(this.entryName(timeEntry), 0);
    const hslaEnd = this.colors.toHsla(this.entryName(timeEntry), 100);

    fadeout.css('background', `-webkit-linear-gradient(${hslaStart} 0%, ${hslaEnd} 100%`);

    ['-moz-linear-gradient', '-o-linear-gradient', 'linear-gradient', '-ms-linear-gradient'].forEach(((style) => {
      fadeout.css('background-image', `${style}(${hslaStart} 0%, ${hslaEnd} 100%`);
    }));

    $element
      .append(fadeout);
  }

  private beforeEventRemove(event:CalendarViewEvent):void {
    if (!event.event.extendedProps.entry) {
      return;
    }

    this.removeTooltip(event);
  }

  private entryName(entry:TimeEntryResource):string {
    let { name } = entry.project;
    if (entry.workPackage) {
      name += ` - ${this.workPackageName(entry)}`;
    }

    return name || '-';
  }

  private workPackageName(entry:TimeEntryResource):string {
    const workPackage = entry.workPackage as WorkPackageResource;
    return `#${idFromLink(workPackage.href)}: ${workPackage.name}`;
  }

  private tooltipContentString(entry:TimeEntryResource, schema:TimeEntrySchema):string {
    return `
        <ul class="tooltip--map">
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${schema.project.name}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(entry.project.name)}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${schema.workPackage.name}:</span>
            <span class="tooltip--map--value">${entry.workPackage ? this.sanitizedValue(this.workPackageName(entry)) : this.i18n.t('js.placeholders.default')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${schema.activity.name}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(entry.activity.name)}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${schema.hours.name}:</span>
            <span class="tooltip--map--value">${this.timezone.formattedDuration(entry.hours)}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${schema.comment.name}:</span>
            <span class="tooltip--map--value">${entry.comment.raw || this.i18n.t('js.placeholders.default')}</span>
          </li>
        `;
  }

  private sanitizedValue(value:string):string {
    return this.sanitizer.sanitize(SecurityContext.HTML, value) || '';
  }

  protected formatNumber(value:number):string {
    return this.i18n.toNumber(value, { precision: 2 });
  }

  private smallerSuitableRatio(value:number):number {
    for (let divisor = this.labelIntervalHours + 1; divisor < 100; divisor++) {
      const candidate = this.labelIntervalHours / divisor;

      if (value >= candidate) {
        return candidate;
      }
    }

    return 1;
  }

  protected setHiddenDays(displayedDays:DisplayedDays) {
    return Array
      .from(displayedDays, (value, index) => {
        if (!value) {
          return (index + 1) % 7;
        }
        return null;
      })
      .filter((value) => value !== null) as number[];
  }
}
