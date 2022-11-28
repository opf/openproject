import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injector,
  OnInit,
  ViewChild,
} from '@angular/core';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from '../modal/modal.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import {
  CalendarOptions,
  DayCellMountArg,
  DayHeaderMountArg,
  Duration,
  EventApi,
  EventInput,
} from '@fullcalendar/core';
import listPlugin from '@fullcalendar/list';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { FullCalendarComponent } from '@fullcalendar/angular';
import { DayResourceService }  from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';

export const listCalendarSelector = 'op-list-calendar';

@Component({
  selector: listCalendarSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['./op-list-calendar.component.sass'],
  templateUrl: './op-list-calendar.component.html',
})
export class OpListCalendarComponent implements OnInit {

  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;
  
  protected memoizedTimeEntries:{ start:Date, end:Date, entries:Promise<CollectionResource<TimeEntryResource>> };
  calendarOptions:CalendarOptions = {
    
    plugins: [ listPlugin ],
    initialView: 'listYear',
    editable: false,
    fixedWeekCount: false,
    height: 550,
    headerToolbar: {
      right: 'prev,next',
      center: '',
      left: 'title',
    },
  
    events: this.calendarEventsFunction.bind(this),
  };
  nonWorkingDays : IDay[];
  constructor(
    readonly elementRef:ElementRef,
    protected I18n:I18nService,
    protected bannersService:BannersService,
    protected opModalService:OpModalService,
    readonly injector:Injector,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly dayService:DayResourceService,
  ) {
    populateInputsFromDataset(this);
  }

  ngOnInit():void {
  
  }

  public calendarEventsFunction(
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):void|PromiseLike<EventInput[]> {
    const today = moment().startOf('day').toDate();
    this.dayService.requireNonWorkingYear$(today).toPromise()
      .then((collection) => {
        
        successCallback(this.mapToCalendarEvents(collection));
      })
      .catch(failureCallback);
  }


  private mapToCalendarEvents(nonWorkingDays:IDay[]) {
    return nonWorkingDays.map((NWD:IDay) => {
      return {
        title: NWD.name,
        start: NWD.date,
      };
    }).filter((event) => !!event) as EventInput[];
  }
}
