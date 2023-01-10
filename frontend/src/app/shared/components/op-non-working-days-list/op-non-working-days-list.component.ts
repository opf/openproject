import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostBinding,
  Injector,
  Input,
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

export interface INonWorkingDay {
  id:string;
  name:string;
  date:string;
  _destroy:boolean | null;
}

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

  @Input() public modifiedNonWorkingDays:INonWorkingDay[] = [];

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
    contentHeight: 'auto',
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
        this.addRemovedNonWorkingdayInputs({ id: event.id, name: event.title, date: event.startStr } as unknown as INonWorkingDay);
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
    readonly confirmDialogService:ConfirmDialogService,
  ) {
    populateInputsFromDataset(this);
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

  ngOnInit():void {
    if (this.modifiedNonWorkingDays.length > 0) {
      const removedNWD = this.modifiedNonWorkingDays.filter((event) => event._destroy === true);
      if (removedNWD.length > 0) {
        removedNWD.forEach((NWD) => {
          this.addRemovedNonWorkingdayInputs(NWD);
        });
      }
    }
  }

  public calendarEventsFunction(
    fetchInfo:{ start:Date },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):void | PromiseLike<EventInput[]> {
    this.dayService.requireNonWorkingYear$(fetchInfo.start)
      .subscribe(
        (days:IDay[]) => {
          this.nonWorkingDays = days;
          if (this.modifiedNonWorkingDays.length > 0) {
            this.mergeEvents(this.modifiedNonWorkingDays);
          }
          const events = this.mapToCalendarEvents(this.nonWorkingDays);
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

  private mergeEvents(modifiedNonWorkingDays:INonWorkingDay[]) {
    const removedNWD = modifiedNonWorkingDays.filter((event) => event._destroy === true);
    const addedNWD = modifiedNonWorkingDays.filter((event) => event.id === null).map((NWD) => ({
      name: NWD.name,
      date: NWD.date,
    })) as IDay[];

    this.nonWorkingDays = this.nonWorkingDays.filter((ar) => !removedNWD.find((rm) => (rm._destroy === true && rm.id === ar.id)));
    this.nonWorkingDays = [...this.nonWorkingDays, ...addedNWD];
  }

  private addNonWorkingdayInputs(event:IDay):void {
    const element = jQuery(this.elementRef.nativeElement);
    element
      .parent()
      .append(`<input type="hidden" name="settings[non_working_days_attributes]['${event.id}'][date]" value="${event.date}" id="${event.id}"/>`);

    element
      .parent()
      .append(`<input type="hidden" name="settings[non_working_days_attributes]['${event.id}'][name]" value="${event.name}" id="${event.id}"/>`);
  }

  private addRemovedNonWorkingdayInputs(event:INonWorkingDay):void {
    const element = jQuery(this.elementRef.nativeElement);
    const id = event.id.substring(0, 3);
    if (id !== 'new') {
      this.removedNonWorkingDays.push(moment(event.date).format('MMMM DD, YYYY'));

      element
        .parent()
        .append(`<input type="hidden" name="settings[non_working_days_attributes]['${event.id}'][id]" value="${event.id}"/>`);

      element
        .parent()
        .append(`<input type="hidden" name="settings[non_working_days_attributes]['${event.id}'][date]" value="${event.date}"/>`);

      element
        .parent()
        .append(`<input type="hidden" name="settings[non_working_days_attributes]['${event.id}'][name]" value="${event.name}"/>`);

      element
        .parent()
        .append(`<input type="hidden" name="settings[non_working_days_attributes]['${event.id}'][_destroy]" value="true"/>`);
    } else {
      const newHiddenInputs = document.querySelectorAll(`#${event.id}`);
      newHiddenInputs.forEach((input) => input.remove());
    }
  }

  public addNonWorkingDay():void {
    // opens date picker modal
    // now I am just testing adding new event to the calendar, will be removed
    const id = (Math.floor(Date.now() / 1000)).toString();
    const eventId = `new${id}`;
    const day = {
      start: '2023-12-23', date: '2023-12-23', title: 'test4', name: 'test4', id: eventId,
    } as unknown as IDay;
    const api = this.ucCalendar.getApi();
    this.nonWorkingDays.push(day as unknown as IDay);
    api.addEvent({ ...day });
    this.addNonWorkingdayInputs(day);
  }
}
