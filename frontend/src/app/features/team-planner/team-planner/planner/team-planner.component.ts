import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { EventInput } from '@fullcalendar/core';
import resourceTimelinePlugin from '@fullcalendar/resource-timeline';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

console.log(resourceTimelinePlugin);

@Component({
  selector: 'op-team-planner',
  templateUrl: './team-planner.component.html',
  styleUrls: ['./team-planner.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TeamPlannerComponent {
  calendarOptions = {
    schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
    editable: false,
    locale: this.I18n.locale,
    fixedWeekCount: false,
    firstDay: this.configuration.startOfWeek(),
    events: this.calendarEventsFunction.bind(this) as unknown,
    // toolbar: this.buildHeader(),
    plugins: [
      resourceTimelinePlugin,
    ],
    initialView: 'resourceTimelineWeekDaysOnly',
    height: 500,
    views: {
      resourceTimelineWeekDaysOnly: {
        type: 'resourceTimeline',
        duration: { weeks: 1 },
        slotDuration: { days: 1 },
      },
    },
    resources: [
      {
        id: '1',
        title: 'User 1',
      },
    ],
  };

  constructor(
    readonly I18n:I18nService,
    readonly configuration:ConfigurationService,
  ) {}

  public calendarEventsFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:any) => void,
  ):void|PromiseLike<EventInput[]> {
    successCallback([{
      title: 'Important todo',
      start: '2021-11-10',
      end: '2021-11-21',
      resourceId: '1',
      allDay: true,
    }]);
  }

  public buildHeader():{ right:string, center:string, left:string } {
    return {
      right: 'dayGridWeek',
      center: 'title',
      left: 'prev,next today',
    };
  }
}
