import {AfterViewInit, Component, Input, OnDestroy, OnInit, ViewChild} from "@angular/core";
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

@Component({
  templateUrl: './wp-calendar.template.html',
  selector: 'wp-calendar',
})

export class WorkPackagesCalendarController implements OnInit, OnDestroy, AfterViewInit {
  calendarOptions:Options;
  events:any;
  @ViewChild(CalendarComponent) ucCalendar:CalendarComponent;
  @Input() projectIdentifier:string;

  constructor(readonly states:States,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpListService:WorkPackagesListService,
              readonly tableState:TableState) {
  }

  ngOnInit() {
    // Clear any old table subscribers
    this.tableState.stopAllSubscriptions.next();
    let calendar = this.ucCalendar;

    this.calendarOptions = {
      editable: false,
      eventLimit: false,
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

    this.tableState.results.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((results:WorkPackageCollectionResource) => {
      this.events = results.elements.map((result:WorkPackageResource) => {
        let startDate = result.startDate;
        let endDate = result.dueDate;

        if (result.isMilestone) {
          startDate = result.date;
          endDate = result.date;
        }

        return {
          title: result.subject,
          start: startDate,
          end: endDate,
          className: `__hl_row_type_${result.type.getId()}`
        };
      });

    });
  }

  ngAfterViewInit() {
    //setTimeout(() => this.ucCalendar.fullCalendar('gotoDate', '2018-09-01'));
  }

  ngOnDestroy() {
    // nothing to do
  }

  public updateTimeframe($event:any) {
    let calendarView = jQuery($event.currentTarget).fullCalendar('getView')!;
    let startDate = (calendarView.start as Moment).format('YYYY-MM-DD');
    let endDate = (calendarView.end as Moment).format('YYYY-MM-DD');

    if (!this.wpTableFilters.currentState) {
      let query_props = `{%22f%22:[{%20%22n%22:%20%22status%22,%20%22o%22:%20%22o%22,%20%22v%22:[]%20},%20{%20%22n%22:%22datesInterval%22,%20%22o%22:%20%22%3C%3Ed%22,%20%22v%22:%20[%22${startDate}%22,%20%22${endDate}%22]%20}],%22pp%22:50}`;

      this.wpListService.fromQueryParams({ query_props: query_props }, this.projectIdentifier).toPromise();
    } else {
      let filtersState = this.wpTableFilters.currentState;

      let datesIntervalFilter = _.find(filtersState.current, {'id': 'datesInterval'})!;

      datesIntervalFilter.values[0] = startDate;
      datesIntervalFilter.values[1] = endDate;

      this.wpTableFilters.replace(filtersState);
    }
  }
}
