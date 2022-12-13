import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostBinding,
  Injector,
  OnInit,
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
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { ConfirmDialogOptions } from '../modals/confirm-dialog/confirm-dialog.modal';

export const nonWorkingDaysListSelector = 'op-non-working-days-list';

@Component({
  selector: nonWorkingDaysListSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  styleUrls: ['./op-non-working-days-list.component.sass'],
  templateUrl: './op-non-working-days-list.component.html',
})
export class OpNonWorkingDaysListComponent implements OnInit {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @HostBinding('class.op-non-working-days-list') className = true;

  text = {
    empty_state_header: this.I18n.t('js.admin.working_days.calendar.empty_state_header'),
    empty_state_description: this.I18n.t('js.admin.working_days.calendar.empty_state_description'),
    new_date: this.I18n.t('js.admin.working_days.calendar.new_date'),
    add_non_working_day: this.I18n.t('js.admin.working_days.add_non_working_day'),
    change_description: this.I18n.t('js.admin.working_days.change_description'),
    warning: this.I18n.t('js.admin.working_days.warning'),
    change_button: this.I18n.t('js.admin.working_days.change_button'),
    change_title: this.I18n.t('js.admin.working_days.change_title'),
    removed_title: this.I18n.t('js.admin.working_days.removed_title'),
  };

  form_submitted = false;

  nonWorkingDays:IDay[] = [];

  removedNonWorkingDays:string[] = [];

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
        this.removedNonWorkingDays.push(moment(event.id).format('MMMM DD, YYYY'));
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
    readonly confirmDialogService:ConfirmDialogService,
  ) {
    populateInputsFromDataset(this);
  }

  ngOnInit():void {
    document.addEventListener('submit', (evt:Event) => {
      if (this.form_submitted === false) {
        this.form_submitted = true;
        const target = evt.target as HTMLFormElement;
        const options:ConfirmDialogOptions = {
          text: {
            text: this.text.change_description,
            title: this.text.change_title,
            button_continue: this.text.change_button,
          },
          dangerHighlighting: true,
          divideContent: true,
          showListData: this.removedNonWorkingDays.length > 0,
          warningText: this.text.warning,
          passedData: this.removedNonWorkingDays,
          listTitle: this.text.removed_title,
        };
        evt.preventDefault();
        void this.confirmDialogService.confirm(options).then(() => {
          this.form_submitted = false;
          target.submit();
        });
      }
    });
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
          // test
          this.nonWorkingDays = this.nonWorkingDays.concat(days);
          this.nonWorkingDays = this.nonWorkingDays.filter((item, pos) => this.nonWorkingDays.indexOf(item) === pos);
          successCallback(events);
        },
        failureCallback,
      );
  }

  private mapToCalendarEvents(nonWorkingDays:IDay[]) {
    return nonWorkingDays.map((NWD:IDay) => ({
      title: NWD.name,
      start: NWD.date,
      id: NWD.id,
    })).filter((event) => !!event) as EventInput[];
  }

  public addNonWorkingDay():void {
    // opens date picker modal

    // now I am just testing adding new event to the calendar, will be removed
    const day = { start: '2022-12-22', title: 'test' };
    const api = this.ucCalendar.getApi();
    this.nonWorkingDays.push(day as unknown as IDay);
    api.addEvent({ ...day });
  }
}
