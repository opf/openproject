import {Component, OnDestroy, OnInit, ViewChild} from "@angular/core";
import {CalendarComponent} from 'ng-fullcalendar';
import {Options} from 'fullcalendar';
import {States} from "core-components/states.service";
import {TableState} from "core-components/wp-table/table-state/table-state";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {WorkPackageTableFiltersService} from "core-components/wp-fast-table/state/wp-table-filters.service";
import {Moment} from "moment";

@Component({
  templateUrl: './wp-calendar.template.html',
  selector: 'wp-calendar',
})

export class WorkPackagesCalendarController implements OnInit, OnDestroy {
  calendarOptions:Options;
  events:any;
  @ViewChild(CalendarComponent) ucCalendar:CalendarComponent;


  constructor(readonly states:States,
              readonly wpTableFilters:WorkPackageTableFiltersService,
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
        right: ''
      },
      events: []
    };

    this.tableState.results.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((results:WorkPackageCollectionResource) => {
      this.events = results.elements.map((result:WorkPackageResource) => {
        return {
          title: result.subject,
          start: result.startDate,
          end: result.dueDate
        };
      });

    });
  }

  ngOnDestroy() {
    // nothing to do
  }

  public updateTimeframe($event:any) {
    if (!this.wpTableFilters.currentState) {
      return;
    }

    let filtersState = this.wpTableFilters.currentState;

    let startDateFilter = _.find(filtersState.current, { 'id': 'startDate' })!;
    let dueDateFilter = _.find(filtersState.current, { 'id': 'dueDate' })!;

    let calendarView = jQuery($event.currentTarget).fullCalendar('getView')!;

    startDateFilter.values[0] = (calendarView.start as Moment).format('YYYY-MM-DD');
    dueDateFilter.values[1] = (calendarView.end as Moment).format('YYYY-MM-DD');

    this.wpTableFilters.replace(filtersState);
  }
}
