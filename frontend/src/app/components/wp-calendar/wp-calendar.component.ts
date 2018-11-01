import {Component, ElementRef, Input, OnDestroy, OnInit, ViewChild} from "@angular/core";
import {CalendarComponent} from 'ng-fullcalendar';
import {Options} from 'fullcalendar';
import {States} from "core-components/states.service";
import {TableState} from "core-components/wp-table/table-state/table-state";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {WorkPackageTableFiltersService} from "core-components/wp-fast-table/state/wp-table-filters.service";
import {Moment} from "moment";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";
import {StateService} from "@uirouter/core";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import * as moment from "moment";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  templateUrl: './wp-calendar.template.html',
  selector: 'wp-calendar',
})

export class WorkPackagesCalendarController implements OnInit, OnDestroy {
  calendarOptions:Options;
  events:any;
  @ViewChild(CalendarComponent) ucCalendar:CalendarComponent;
  @Input() projectIdentifier:string;
  @Input() static:boolean = false;

  constructor(readonly states:States,
              readonly $state:StateService,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpListService:WorkPackagesListService,
              readonly tableState:TableState,
              readonly urlParamsHelper:UrlParamsHelperService,
              private element:ElementRef,
              readonly i18n:I18nService) {
  }

  ngOnInit() {
    // Clear any old subscribers
    this.tableState.stopAllSubscriptions.next();

    this.setCalendarOptions();

    this.setupWorkPackagesListener();
  }

  ngOnDestroy() {
    // nothing to do
  }

  public updateTimeframe($event:any) {
    let calendarView = this.calendarElement.fullCalendar('getView')!;
    let startDate = (calendarView.start as Moment).format('YYYY-MM-DD');
    let endDate = (calendarView.end as Moment).format('YYYY-MM-DD');

    if (!this.wpTableFilters.currentState && this.states.query.resource.value) {
      // nothing to do
    } else if (!this.wpTableFilters.currentState) {
      let queryProps = this.defaultQueryProps(startDate, endDate);

      if (this.$state.params.query_props) {
        queryProps = this.$state.params.query_props;
      }

      this.wpListService.fromQueryParams({ query_props: queryProps }, this.projectIdentifier).toPromise();
    } else {
      let params = this.$state.params;
      let filtersState = this.wpTableFilters.currentState;

      let datesIntervalFilter = _.find(filtersState.current, {'id': 'datesInterval'})!;

      datesIntervalFilter.values[0] = startDate;
      datesIntervalFilter.values[1] = endDate;

      this.wpTableFilters.replace(filtersState);
    }
  }

  private get calendarElement() {
    return jQuery(this.element.nativeElement).find('ng-fullcalendar');
  }

  private setCalendarsDate() {
    if (!this.states.query.resource.value) {
      return;
    }

    let query = this.states.query.resource.value;

    let datesIntervalFilter = _.find(query.filters || [], {'id': 'datesInterval'})!;

    let calendarDate = moment();

    if (datesIntervalFilter) {
      let lower = moment(datesIntervalFilter.values[0] as string);
      let upper = moment(datesIntervalFilter.values[1] as string);

      calendarDate = lower.add(upper.diff(lower, 'days') / 2, 'days');
    }

    this.calendarElement.fullCalendar('gotoDate', calendarDate.format('YYYY-MM-DD'));
  }

  private setupWorkPackagesListener() {
    this.tableState.results.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((collection:WorkPackageCollectionResource) => {
      this.mapToCalendarEvents(collection.elements);
      this.setCalendarsDate();
    });
  }

  private mapToCalendarEvents(workPackages:WorkPackageResource[]) {
    this.events = workPackages.map((workPackage:WorkPackageResource) => {
      let startDate = workPackage.startDate;
      let endDate = workPackage.dueDate;

      if (workPackage.isMilestone) {
        startDate = workPackage.date;
        endDate = workPackage.date;
      }

      return {
        title: workPackage.subject,
        start: startDate,
        end: endDate,
        className: `__hl_row_type_${workPackage.type.getId()}`
      };
    });
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
        return jQuery(window).height() - this.calendarElement.offset().top - 12;
      },
      header: {
        left: 'prev,next today',
        center: 'title',
        right: 'month,basicWeek'
      },
      events: [],
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
      eventLimit: 17,
      locale: this.i18n.locale,
      height: 400,
      header: {
        left: '',
        center: '',
        right: ''
      },
      defaultView: 'basicWeek',
      events: []
    };
  }

  private defaultQueryProps(startDate:string, endDate:string) {
    return `{"c": ["id"], "t": "id:asc", "f":[{ "n": "status", "o": "o", "v": [] }, { "n": "datesInterval", "o": "<>d", "v": ["${startDate}", "${endDate}"] }], "pp": 50}`;
  }
}
