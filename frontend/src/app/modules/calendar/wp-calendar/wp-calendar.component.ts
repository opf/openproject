import {Component, ElementRef, Input, OnDestroy, OnInit, SecurityContext, ViewChild} from "@angular/core";
import {CalendarComponent} from 'ng-fullcalendar';
import {Options} from 'fullcalendar';
import {States} from "core-components/states.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {WorkPackageTableFiltersService} from "core-components/wp-fast-table/state/wp-table-filters.service";
import * as moment from "moment";
import {Moment} from "moment";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";
import {StateService} from "@uirouter/core";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {DomSanitizer} from "@angular/platform-browser";
import {WorkPackagesListChecksumService} from "core-components/wp-list/wp-list-checksum.service";
import {OpTitleService} from "core-components/html/op-title.service";

@Component({
  templateUrl: './wp-calendar.template.html',
  styleUrls: ['./wp-calendar.sass'],
  selector: 'wp-calendar',
})
export class WorkPackagesCalendarController implements OnInit, OnDestroy {
  calendarOptions:Options;
  @ViewChild(CalendarComponent, { static: false }) ucCalendar:CalendarComponent;
  @Input() projectIdentifier:string;
  @Input() static:boolean = false;
  static MAX_DISPLAYED = 100;

  constructor(readonly states:States,
              readonly $state:StateService,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpListService:WorkPackagesListService,
              readonly querySpace:IsolatedQuerySpace,
              readonly wpListChecksumService:WorkPackagesListChecksumService,
              readonly titleService:OpTitleService,
              readonly urlParamsHelper:UrlParamsHelperService,
              private element:ElementRef,
              readonly i18n:I18nService,
              readonly notificationsService:NotificationsService,
              private sanitizer:DomSanitizer) { }

  ngOnInit() {
    // Clear any old subscribers
    this.querySpace.stopAllSubscriptions.next();

    this.setCalendarOptions();
  }

  ngOnDestroy() {
    // nothing to do
  }

  public onCalendarInitialized() {
    this.setupWorkPackagesListener();
  }

  public updateTimeframe($event:any) {
    let calendarView = this.calendarElement.fullCalendar('getView')!;
    let startDate = (calendarView.start as Moment).format('YYYY-MM-DD');
    let endDate = (calendarView.end as Moment).format('YYYY-MM-DD');
    let filtersEmpty = this.wpTableFilters.isEmpty;

    if (filtersEmpty && this.querySpace.query.value) {
      // nothing to do
    } else if (filtersEmpty) {
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

  public addTooltip($event:any) {
    let event = $event.detail.event;
    let element = $event.detail.element;
    let workPackage = event.workPackage;

    jQuery(element).tooltip({
      content: this.contentString(workPackage),
      items: '.fc-content',
      close: function () { jQuery(".ui-helper-hidden-accessible").remove(); },
      track: true
    });
  }

  public toWPFullView($event:any) {
    let workPackage = $event.detail.event.workPackage;

    // do not display the tooltip on the wp show page
    this.removeTooltip($event.detail.jsEvent.currentTarget);

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
    return jQuery(this.element.nativeElement).find('ng-fullcalendar');
  }

  private setCalendarsDate() {
    const query = this.querySpace.query.value;
    if (!query) {
      return;
    }

    let datesIntervalFilter = _.find(query.filters || [], {'id': 'datesInterval'}) as any;

    let calendarDate:any = null;
    let calendarUnit = 'month';

    if (datesIntervalFilter) {
      let lower = moment(datesIntervalFilter.values[0] as string);
      let upper = moment(datesIntervalFilter.values[1] as string);
      let diff = upper.diff(lower, 'days');

      calendarDate = lower.add(diff / 2, 'days');

      if (diff === 7) {
        calendarUnit = 'basicWeek';
      }
    }

    if (calendarDate) {
      this.calendarElement.fullCalendar('changeView', calendarUnit, calendarDate);
    } else {
      this.calendarElement.fullCalendar('changeView', calendarUnit);
    }
  }

  private setupWorkPackagesListener() {
    this.querySpace.results.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((collection:WorkPackageCollectionResource) => {
      this.warnOnTooManyResults(collection);
      this.mapToCalendarEvents(collection.elements);
      this.setCalendarsDate();
    });
  }

  private mapToCalendarEvents(workPackages:WorkPackageResource[]) {
    let events = workPackages.map((workPackage:WorkPackageResource) => {
      let startDate = this.eventDate(workPackage, 'start');
      let endDate = this.eventDate(workPackage, 'due');

      let exclusiveEnd = moment(endDate).add(1, 'days');

      return {
        title: workPackage.subject,
        start: startDate,
        end: exclusiveEnd,
        allDay: true,
        className: `__hl_background_type_${workPackage.type.id}`,
        workPackage: workPackage
      };
    });

    // Instead of using two way bindings we manually trigger
    // event rendering here. For whatever reasons, when embedded
    // in a grid, having two way binding will lead to having constantly
    // removed the events after showing them initially.
    // It appears as if the two way binding is initialized twice if used.
    this.ucCalendar.renderEvents(events);
  }

  private warnOnTooManyResults(collection:WorkPackageCollectionResource) {
    if (collection.count < collection.total) {
      const message = this.i18n.t('js.calendar.too_many',
                                  { count: collection.total,
                                               max: WorkPackagesCalendarController.MAX_DISPLAYED });
      this.notificationsService.addNotice(message);
    }
  }

  private setCalendarOptions() {
    if (this.static) {
      this.calendarOptions = this.staticOptions;
    } else {
      this.calendarOptions = this.dynamicOptions;
    }
  }

  private get dynamicOptions() {
    return {
      editable: false,
      eventLimit: false,
      locale: this.i18n.locale,
      height: () => {
        // -12 for the bottom padding
        return jQuery(window).height()! - this.calendarElement.offset()!.top - 12;
      },
      header: {
        left: 'prev,next today',
        center: 'title',
        right: 'month,basicWeek'
      },
      views: {
        month: {
          fixedWeekCount: false
        }
      }
    };
  }

  private get staticOptions() {
    return {
      editable: false,
      eventLimit: false,
      locale: this.i18n.locale,
      height: () => {
        let heightElement = jQuery(this.element.nativeElement);

        while (!heightElement.height() && heightElement.parent()) {
          heightElement = heightElement.parent();
        }

        let topOfCalendar = jQuery(this.element.nativeElement).position().top;
        let topOfHeightElement = heightElement.position().top;

        return heightElement.height()! - (topOfCalendar - topOfHeightElement);
      },
      header: false,
      defaultView: 'basicWeek'
    };
  }

  private defaultQueryProps(startDate:string, endDate:string) {
    let props = { "c": ["id"],
                  "t":
                  "id:asc",
                  "f": [{ "n": "status", "o": "o", "v": [] },
                        { "n": "datesInterval", "o": "<>d", "v": [startDate, endDate] }],
                  "pp": WorkPackagesCalendarController.MAX_DISPLAYED };

    return JSON.stringify(props);
  }

  private eventDate(workPackage:WorkPackageResource, type:'start'|'due') {
    if (workPackage.isMilestone) {
      return workPackage.date;
    } else {
      return workPackage[`${type}Date`];
    }
  }

  private contentString(workPackage:WorkPackageResource) {
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

  private removeTooltip(target:ElementRef) {
    // deactivate tooltip so that it is not displayed on the wp show page
    jQuery(target).tooltip({
      close: function () { jQuery(".ui-helper-hidden-accessible").remove(); },
      disabled: true
    });
  }
}
