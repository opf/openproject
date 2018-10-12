import {Component, OnDestroy, OnInit, ViewChild} from "@angular/core";
import {CalendarComponent} from 'ng-fullcalendar';
import {Options} from 'fullcalendar';

@Component({
  templateUrl: './wp-calendar.template.html',
  selector: 'wp-calendar',
})

export class WorkPackagesCalendarController implements OnInit {
  calendarOptions:Options;
  @ViewChild(CalendarComponent) ucCalendar:CalendarComponent;

  //constructor() {}

  ngOnInit() {
    this.calendarOptions = {
      editable: false,
      eventLimit: false,
      header: {
        left: 'prev,next today',
        center: 'title',
        right: 'month,agendaWeek,agendaDay,listMonth'
      },
      events: []
    };
  }

}
