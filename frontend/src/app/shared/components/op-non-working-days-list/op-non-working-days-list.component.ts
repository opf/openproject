import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostBinding,
  Injector,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from '../modal/modal.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { FullCalendarComponent } from '@fullcalendar/angular';
import {
  EventInput,
  CalendarOptions,
} from '@fullcalendar/core';
import listPlugin from '@fullcalendar/list';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { CalendarViewEvent } from 'core-app/features/calendar/op-work-packages-calendar.service';
import { opIconElement } from 'core-app/shared/helpers/op-icon-builder';

export const nonWorkingDaysListSelector = 'op-non-working-days-list';

@Component({
  selector: nonWorkingDaysListSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  styleUrls: ['./op-non-working-days-list.component.sass'],
  templateUrl: './op-non-working-days-list.component.html',
})
export class OpNonWorkingDaysListComponent {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @HostBinding('class.op-non-working-days-list') className = true;

  text = {
    empty_state_header: this.I18n.t('js.admin.working_days.calendar.empty_state_header'),
    empty_state_description: this.I18n.t('js.admin.working_days.calendar.empty_state_description'),
    add_non_working_day: this.I18n.t('js.admin.working_days.add_non_working_day'),
  };

  calendarOptions:CalendarOptions = {
    plugins: [listPlugin],
    initialView: 'listYear',
    headerToolbar: {
      right: 'prev,next',
      center: '',
      left: 'title',
    },
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    events: this.calendarEventsFunction.bind(this),
    eventDidMount: (evt:CalendarViewEvent) => {
      const { el, event } = evt;
      const td = document.createElement('td');
      const anchor = document.createElement('a');
      anchor.title = 'Delete';
      anchor.href = '#';
      anchor.classList.add('fc-list-day-side-text', 'op-non-working-days-list--delete-icon');
      anchor.appendChild(opIconElement('icon', 'icon-delete'));
      anchor.addEventListener('click', () => {
        event.remove();
      });
      td.appendChild(anchor);
      el.appendChild(td);
    },
    noEventsContent: { html: `<table class="fc-list-table"><tbody><th><div class="fc-list-day-cushion"><a class="fc-list-day-text">${this.text.empty_state_header}</a></div></th><tr class="fc-event"><td>${this.text.empty_state_description}</td></tr></tbody></table>` },

  };

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

  public calendarEventsFunction(
    fetchInfo:{ start:Date },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):void|PromiseLike<EventInput[]> {
    this.dayService.requireNonWorkingYear$(fetchInfo.start)
      .subscribe(
        (days:IDay[]) => {
          const events = this.mapToCalendarEvents(days);
          successCallback(events);
        },
        failureCallback,
      );
  }

  private mapToCalendarEvents(nonWorkingDays:IDay[]) {
    return nonWorkingDays.map((NWD:IDay) => ({
      title: NWD.name,
      start: NWD.date,
    })).filter((event) => !!event) as EventInput[];
  }

  public addNonWorkingDay():void {
    // opens date picker modal
  }
}
