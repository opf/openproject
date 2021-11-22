import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import dayGridPlugin from '@fullcalendar/daygrid';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { EventInput } from '@fullcalendar/core';

@Component({
  selector: 'op-team-planner',
  templateUrl: './team-planner.component.html',
  styleUrls: ['./team-planner.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TeamPlannerComponent {
  calendarOptions = {
    editable: false,
    locale: this.I18n.locale,
    fixedWeekCount: false,
    firstDay: this.configuration.startOfWeek(),
    events: this.calendarEventsFunction.bind(this) as unknown,
    toolbar: this.buildHeader(),
    plugins: [dayGridPlugin],
    initialView: 'dayGridMonth',
    height: 500,
  };

  constructor(
    readonly I18n:I18nService,
    readonly configuration:ConfigurationService,
  ) {}

  public calendarEventsFunction(fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void):void|PromiseLike<EventInput[]> {
    successCallback([{
      title: 'Important todo',
      start: '2021-11-10',
      end: '2021-11-21',
      allDay: true,
    }]);
  }

  public buildHeader():{ right:string, center:string, left:string } {
    return {
      right: 'dayGridMonth,dayGridWeek',
      center: 'title',
      left: 'prev,next today',
    };
  }
}
