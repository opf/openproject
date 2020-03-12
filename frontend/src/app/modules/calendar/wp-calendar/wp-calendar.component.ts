import {AfterViewInit, Component, ElementRef, Input, OnInit, SecurityContext, ViewChild} from "@angular/core";
import {FullCalendarComponent} from '@fullcalendar/angular';
import {States} from "core-components/states.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {WorkPackageViewFiltersService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import * as moment from "moment";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";
import {StateService} from "@uirouter/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {DomSanitizer} from "@angular/platform-browser";
import {WorkPackagesListChecksumService} from "core-components/wp-list/wp-list-checksum.service";
import {OpTitleService} from "core-components/html/op-title.service";
import dayGridPlugin from '@fullcalendar/daygrid';
import {EventApi, EventInput} from '@fullcalendar/core';
import {EventSourceError} from '@fullcalendar/core/structs/event-source';
import {take} from 'rxjs/operators';
import {ToolbarInput} from '@fullcalendar/core/types/input-types';
import {ConfigurationService} from "core-app/modules/common/config/configuration.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

interface CalendarViewEvent {
  el:HTMLElement;
  event:EventApi;
  jsEvent:MouseEvent;
}

@Component({
  templateUrl: './wp-calendar.template.html',
  styleUrls: ['./wp-calendar.sass'],
  selector: 'wp-calendar',
})
export class WorkPackagesCalendarController extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;
  @Input() projectIdentifier:string;
  @Input() static:boolean = false;
  static MAX_DISPLAYED = 100;

  public tooManyResultsText:string|null;

  public calendarPlugins = [dayGridPlugin];
  public calendarHeight:Function;
  public calendarEvents:Function;
  public calendarHeader:ToolbarInput|boolean;

  private alreadyLoaded = false;

  constructor(readonly states:States,
              readonly $state:StateService,
              readonly wpTableFilters:WorkPackageViewFiltersService,
              readonly wpListService:WorkPackagesListService,
              readonly querySpace:IsolatedQuerySpace,
              readonly wpListChecksumService:WorkPackagesListChecksumService,
              readonly titleService:OpTitleService,
              private element:ElementRef,
              readonly i18n:I18nService,
              readonly notificationsService:NotificationsService,
              private sanitizer:DomSanitizer,
              private configuration:ConfigurationService) {
    super();
  }

  ngOnInit() {
    // Clear any old subscribers
    this.querySpace.stopAllSubscriptions.next();

    this.setupWorkPackagesListener();

    this.initializeCalendar();
  }

  ngAfterViewInit() {
    // The full-calendar component's outputs do not seem to work
    // see: https://github.com/fullcalendar/fullcalendar-angular/issues/228#issuecomment-523505044
    // Therefore, setting the outputs via the underlying API
    this.ucCalendar.getApi().setOption('eventRender', (event:CalendarViewEvent) => {
      this.addTooltip(event);
    });
    this.ucCalendar.getApi().setOption('eventClick', (event:CalendarViewEvent) => {
      this.toWPFullView(event);
    });
  }

  public calendarEventsFunction(fetchInfo:{ start:Date, end:Date, timeZone:string },
                                successCallback:(events:EventInput[]) => void,
                                failureCallback:(error:EventSourceError) => void):void|PromiseLike<EventInput[]> {
    if (this.alreadyLoaded) {
      this.alreadyLoaded = false;
      let events = this.updateResults(this.querySpace.results.value!);
      successCallback(events);
    } else {
      this.querySpace.results.values$().pipe(
        take(1)
      ).subscribe((collection:WorkPackageCollectionResource) => {
        let events = this.updateResults((collection));
        successCallback(events);
      });
    }


    this.updateTimeframe(fetchInfo);
  }

  private initializeCalendar() {
    this.calendarEvents = this.calendarEventsFunction.bind(this);
    this.setCalendarHeight();
    this.setCalendarHeader();
  }

  public updateTimeframe(fetchInfo:{ start:Date, end:Date, timeZone:string }) {
    let filtersEmpty = this.wpTableFilters.isEmpty;

    if (filtersEmpty && this.querySpace.query.value) {
      // nothing to do
      return;
    }

    let startDate = moment(fetchInfo.start).format('YYYY-MM-DD');
    let endDate = moment(fetchInfo.end).format('YYYY-MM-DD');

    if (filtersEmpty) {
      let queryProps = this.defaultQueryProps(startDate, endDate);

      if (this.$state.params.query_props) {
        queryProps = decodeURIComponent(this.$state.params.query_props || '');
      }

      this.wpListService.fromQueryParams({ query_props: queryProps }, this.projectIdentifier).toPromise();
    } else {
      let params = this.$state.params;

      this.wpTableFilters.modify('datesInterval', (datesIntervalFilter) => {
        datesIntervalFilter.values[0] = startDate;
        datesIntervalFilter.values[1] = endDate;
      });
    }
  }

  public addTooltip(event:CalendarViewEvent) {
    jQuery(event.el).tooltip({
      content: this.tooltipContentString(event.event.extendedProps.workPackage),
      items: '.fc-event',
      close: function () {
        jQuery(".ui-helper-hidden-accessible").remove();
      },
      track: true
    });
  }

  public toWPFullView(event:CalendarViewEvent) {
    let workPackage = event.event.extendedProps.workPackage;

    if (event.el) {
      // do not display the tooltip on the wp show page
      this.removeTooltip(event.el);
    }

    // Ensure checksum is removed to allow queries to load
    this.wpListChecksumService.clear();

    // Ensure current calendar URL is pushed to history
    window.history.pushState({}, this.titleService.current, window.location.href);

    this.$state.go(
      'work-packages.show',
      { workPackageId: workPackage.id },
      { inherit: false });
  }

  public get calendarEditable() {
    return false;
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
    if (this.static) {
      return 'dayGridWeek';
    } else {
      return null;
    }
  }

  public get calendarFirstDay() {
    return this.configuration.startOfWeek();
  }

  private get calendarElement() {
    return jQuery(this.element.nativeElement).find('.fc-view-container');
  }

  private setCalendarHeight() {
    if (this.static) {
      this.calendarHeight = () => {
        let heightElement = jQuery(this.element.nativeElement);

        while (!heightElement.height() && heightElement.parent()) {
          heightElement = heightElement.parent();
        }

        let topOfCalendar = jQuery(this.element.nativeElement).position().top;
        let topOfHeightElement = heightElement.position().top;

        return heightElement.height()! - (topOfCalendar - topOfHeightElement);
      };
    } else {
      this.calendarHeight = () => {
        // -12 for the bottom padding
        return jQuery(window).height()! - this.calendarElement.offset()!.top - 12;
      };
    }
  }

  public setCalendarHeader() {
    if (this.static) {
      this.calendarHeader = false;
    } else {
      this.calendarHeader = {
        right: 'dayGridMonth,dayGridWeek',
        center: 'title',
        left: 'prev,next today'
      };
    }
  }

  private setCalendarsDate() {
    const query = this.querySpace.query.value;
    if (!query) {
      return;
    }

    let datesIntervalFilter = _.find(query.filters || [], { 'id': 'datesInterval' }) as any;

    let calendarDate:any = null;
    let calendarUnit = 'dayGridMonth';

    if (datesIntervalFilter) {
      let lower = moment(datesIntervalFilter.values[0] as string);
      let upper = moment(datesIntervalFilter.values[1] as string);
      let diff = upper.diff(lower, 'days');

      calendarDate = lower.add(diff / 2, 'days');

      if (diff === 7) {
        calendarUnit = 'dayGridWeek';
      }
    }

    if (calendarDate) {
      this.ucCalendar.getApi().changeView(calendarUnit, calendarDate.toDate());
    } else {
      this.ucCalendar.getApi().changeView(calendarUnit);
    }
  }

  private setupWorkPackagesListener() {
    this.querySpace.results.values$().pipe(
      this.untilDestroyed()
    ).subscribe((collection:WorkPackageCollectionResource) => {
      this.alreadyLoaded = true;
      this.setCalendarsDate();

      this.ucCalendar.getApi().refetchEvents();
    });
  }

  private updateResults(collection:WorkPackageCollectionResource) {
    this.warnOnTooManyResults(collection);

    return this.mapToCalendarEvents(collection.elements);
  }

  private mapToCalendarEvents(workPackages:WorkPackageResource[]) {
    let events = workPackages.map((workPackage:WorkPackageResource) => {
      let startDate = this.eventDate(workPackage, 'start');
      let endDate = this.eventDate(workPackage, 'due');

      let exclusiveEnd = moment(endDate).add(1, 'days').format('YYYY-MM-DD');

      return {
        title: workPackage.subject,
        start: startDate,
        end: exclusiveEnd,
        allDay: true,
        className: `__hl_background_type_${workPackage.type.id}`,
        workPackage: workPackage
      };
    });

    return events;
  }

  private warnOnTooManyResults(collection:WorkPackageCollectionResource) {
    if (collection.count < collection.total) {
      this.tooManyResultsText = this.i18n.t('js.calendar.too_many',
        {
          count: collection.total,
          max: WorkPackagesCalendarController.MAX_DISPLAYED
        });
    } else {
      this.tooManyResultsText = null;
    }

    if (this.tooManyResultsText && !this.static) {
      this.notificationsService.addNotice(this.tooManyResultsText);
    }
  }

  private defaultQueryProps(startDate:string, endDate:string) {
    let props = {
      "c": ["id"],
      "t":
        "id:asc",
      "f": [{ "n": "status", "o": "o", "v": [] },
        { "n": "datesInterval", "o": "<>d", "v": [startDate, endDate] }],
      "pp": WorkPackagesCalendarController.MAX_DISPLAYED
    };

    return JSON.stringify(props);
  }

  private eventDate(workPackage:WorkPackageResource, type:'start'|'due') {
    if (workPackage.isMilestone) {
      return workPackage.date;
    } else {
      return workPackage[`${type}Date`];
    }
  }

  private tooltipContentString(workPackage:WorkPackageResource) {
    return `
        ${this.sanitizedValue(workPackage, 'type')} #${workPackage.id}: ${this.sanitizedValue(workPackage, 'subject', null)}
        <ul class="tooltip--map">
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.work_packages.properties.projectName')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(workPackage, 'project')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.work_packages.properties.status')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(workPackage, 'status')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.work_packages.properties.startDate')}:</span>
            <span class="tooltip--map--value">${this.eventDate(workPackage, 'start')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.work_packages.properties.dueDate')}:</span>
            <span class="tooltip--map--value">${this.eventDate(workPackage, 'due')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.work_packages.properties.assignee')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(workPackage, 'assignee')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.i18n.t('js.work_packages.properties.priority')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(workPackage, 'priority')}</span>
          </li>
        </ul>
        `;
  }

  private sanitizedValue(workPackage:WorkPackageResource, attribute:string, toStringMethod:string|null = 'name') {
    let value = workPackage[attribute];
    value = toStringMethod && value ? value[toStringMethod] : value;
    value = value || this.i18n.t('js.placeholders.default');

    return this.sanitizer.sanitize(SecurityContext.HTML, value);
  }

  private removeTooltip(element:HTMLElement) {
    // deactivate tooltip so that it is not displayed on the wp show page
    jQuery(element).tooltip({
      close: function () {
        jQuery(".ui-helper-hidden-accessible").remove();
      },
      disabled: true
    });
  }
}
