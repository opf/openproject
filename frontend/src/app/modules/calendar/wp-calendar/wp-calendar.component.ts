import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Input,
  OnInit,
  SecurityContext,
  ViewChild
} from "@angular/core";
import { FullCalendarComponent } from '@fullcalendar/angular';
import { States } from "core-components/states.service";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { WorkPackageCollectionResource } from "core-app/modules/hal/resources/wp-collection-resource";
import { WorkPackageViewFiltersService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import * as moment from "moment";
import { WorkPackagesListService } from "core-components/wp-list/wp-list.service";
import { StateService } from "@uirouter/core";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { DomSanitizer } from "@angular/platform-browser";
import { WorkPackagesListChecksumService } from "core-components/wp-list/wp-list-checksum.service";
import { OpTitleService } from "core-components/html/op-title.service";
import dayGridPlugin from '@fullcalendar/daygrid';
import { CalendarOptions, EventApi, EventInput } from '@fullcalendar/core';
import { Subject } from "rxjs";
import { take, debounceTime } from 'rxjs/operators';
import { ToolbarInput } from '@fullcalendar/common';
import { ConfigurationService } from "core-app/modules/common/config/configuration.service";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";

interface CalendarViewEvent {
  el:HTMLElement;
  event:EventApi;
}

@Component({
  templateUrl: './wp-calendar.template.html',
  styleUrls: ['./wp-calendar.sass'],
  selector: 'wp-calendar',
})
export class WorkPackagesCalendarController extends UntilDestroyedMixin implements OnInit {
  private resizeObserver:ResizeObserver;
  private resizeSubject = new Subject<any>();
  private ucCalendar:FullCalendarComponent;
  @ViewChild(FullCalendarComponent)
  set container(v:FullCalendarComponent|undefined) {
    // ViewChild reference may be undefined initially
    // due to ngIf
    if (!v) {
      return;
    }

    this.ucCalendar = v;

    // The full-calendar component's outputs do not seem to work
    // see: https://github.com/fullcalendar/fullcalendar-angular/issues/228#issuecomment-523505044
    // Therefore, setting the outputs via the underlying API
    this.ucCalendar.getApi().setOption('eventDidMount', (event:CalendarViewEvent) => {
      this.addTooltip(event);
    });
    this.ucCalendar.getApi().setOption('eventClick', (event:CalendarViewEvent) => {
      this.toWPFullView(event);
    });
  }
  @ViewChild('ucCalendar', { read: ElementRef })
  set ucCalendarElement(v:ElementRef|undefined) {
    if (!v) {
      return;
    }

    if (!this.resizeObserver) {
      this.resizeObserver = new ResizeObserver(() => this.resizeSubject.next());
    }

    this.resizeObserver.observe(v.nativeElement);
  }

  @Input() projectIdentifier:string;
  @Input() static = false;
  static MAX_DISPLAYED = 100;

  public tooManyResultsText:string|null;

  private alreadyLoaded = false;

  calendarOptions:CalendarOptions|undefined;

  constructor(readonly states:States,
              readonly $state:StateService,
              readonly wpTableFilters:WorkPackageViewFiltersService,
              readonly wpListService:WorkPackagesListService,
              readonly querySpace:IsolatedQuerySpace,
              readonly wpListChecksumService:WorkPackagesListChecksumService,
              readonly schemaCache:SchemaCacheService,
              readonly titleService:OpTitleService,
              private element:ElementRef,
              readonly i18n:I18nService,
              readonly notificationsService:NotificationsService,
              private sanitizer:DomSanitizer,
              private configuration:ConfigurationService) {
    super();
  }

  ngOnInit() {
    this.resizeSubject
      .pipe(debounceTime(50))
      .subscribe(() => {
        this.ucCalendar.getApi().updateSize();
      });

    // Clear any old subscribers
    this.querySpace.stopAllSubscriptions.next();

    this.setupWorkPackagesListener();
    this.initializeCalendar();
  }

  public calendarEventsFunction(fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:any) => void):void|PromiseLike<EventInput[]> {
    if (this.alreadyLoaded) {
      this.alreadyLoaded = false;
      const events = this.updateResults(this.querySpace.results.value!);
      successCallback(events);
    } else {
      this.querySpace.results.values$().pipe(
        take(1)
      ).subscribe((collection:WorkPackageCollectionResource) => {
        const events = this.updateResults((collection));
        successCallback(events);
      });
    }


    this.updateTimeframe(fetchInfo);
  }

  private initializeCalendar() {
    this.configuration.initialized
      .then(() => {
        this.calendarOptions = {
          editable: false,
          locale: this.i18n.locale,
          fixedWeekCount: false,
          firstDay: this.configuration.startOfWeek(),
          events: this.calendarEventsFunction.bind(this),
          plugins: [dayGridPlugin],
          initialView: (() => {
            if (this.static) {
              return 'dayGridWeek';
            } else {
              return undefined;
            }
          })(),
          height: this.calendarHeight(),
          headerToolbar: this.buildHeader()
        };
      });
  }

  public updateTimeframe(fetchInfo:{ start:Date, end:Date, timeZone:string }) {
    const filtersEmpty = this.wpTableFilters.isEmpty;

    if (filtersEmpty && this.querySpace.query.value) {
      // nothing to do
      return;
    }

    const startDate = moment(fetchInfo.start).format('YYYY-MM-DD');
    const endDate = moment(fetchInfo.end).format('YYYY-MM-DD');

    if (filtersEmpty) {
      let queryProps = this.defaultQueryProps(startDate, endDate);

      if (this.$state.params.query_props) {
        queryProps = decodeURIComponent(this.$state.params.query_props || '');
      }

      this.wpListService.fromQueryParams({ query_props: queryProps }, this.projectIdentifier).toPromise();
    } else {
      const params = this.$state.params;

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
    const workPackage = event.event.extendedProps.workPackage;

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
  private get calendarElement() {
    return jQuery(this.element.nativeElement).find('.wp-calendar--container');
  }

  private calendarHeight():number {
    if (this.static) {
      let heightElement = jQuery(this.element.nativeElement);

      while (!heightElement.height() && heightElement.parent()) {
        heightElement = heightElement.parent();
      }

      const topOfCalendar = jQuery(this.element.nativeElement).position().top;
      const topOfHeightElement = heightElement.position().top;

      return heightElement.height()! - (topOfCalendar - topOfHeightElement);
    } else {
      // -12 for the bottom padding
      return jQuery(window).height()! - this.calendarElement.offset()!.top - 12;
    }
  }

  public buildHeader() {
    if (this.static) {
      return false;
    } else {
      return {
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

    const datesIntervalFilter = _.find(query.filters || [], { 'id': 'datesInterval' }) as any;

    let calendarDate:any = null;
    let calendarUnit = 'dayGridMonth';

    if (datesIntervalFilter) {
      const lower = moment(datesIntervalFilter.values[0] as string);
      const upper = moment(datesIntervalFilter.values[1] as string);
      const diff = upper.diff(lower, 'days');

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
    const events = workPackages.map((workPackage:WorkPackageResource) => {
      const startDate = this.eventDate(workPackage, 'start');
      const endDate = this.eventDate(workPackage, 'due');

      const exclusiveEnd = moment(endDate).add(1, 'days').format('YYYY-MM-DD');

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
    const props = {
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
    if (this.schemaCache.of(workPackage).isMilestone) {
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
