import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, HostBinding, Input, OnInit, ViewChild, ViewEncapsulation, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { FullCalendarComponent } from '@fullcalendar/angular';
import { CalendarOptions, EventInput, EventSourceFuncArg } from '@fullcalendar/core';
import listPlugin from '@fullcalendar/list';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { CalendarViewEvent } from 'core-app/features/calendar/op-work-packages-calendar.service';
import { opIconElement } from 'core-app/shared/helpers/op-icon-builder';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import allLocales from '@fullcalendar/core/locales-all';


export interface INonWorkingDay {
  id:string|null;
  name:string;
  date:string;
  _destroy?:boolean;
}

@Component({
  selector: 'opce-non-working-days-list',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  styleUrls: ['./op-non-working-days-list.component.sass'],
  templateUrl: './op-non-working-days-list.component.html',
  standalone: false,
})
export class OpNonWorkingDaysListComponent implements OnInit {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  protected I18n = inject(I18nService);
  readonly dayService = inject(DayResourceService);
  readonly toast = inject(ToastService);
  readonly cdRef = inject(ChangeDetectorRef);

  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @HostBinding('class.op-non-working-days-list') className = true;

  @Input() public modifiedNonWorkingDays:INonWorkingDay[] = [];

  text = {
    empty_state_header: this.I18n.t('js.admin.working_days.calendar.empty_state_header'),
    empty_state_description: this.I18n.t('js.admin.working_days.calendar.empty_state_description'),
    already_added_error: this.I18n.t('js.admin.working_days.already_added_error'),
    new_date: this.I18n.t('js.admin.working_days.calendar.new_date'),
    add_non_working_day: this.I18n.t('js.admin.working_days.add_non_working_day'),
    non_working_day_name: this.I18n.t('js.modals.label_name'),
    add: this.I18n.t('js.button_add'),
  };

  originalNonWorkingDays:INonWorkingDay[] = [];
  nonWorkingDays:INonWorkingDay[] = [];

  datepickerOpened = false;

  selectedNonWorkingDayName = '';

  calendarOptions:CalendarOptions = {
    locales: allLocales,
    locale: this.I18n.locale,
    plugins: [listPlugin],
    initialView: 'listYear',
    contentHeight: 'auto',
    headerToolbar: {
      right: '',
      center: '',
      left: 'prev,next,title',
    },
    events: this.calendarEventsFunction.bind(this),
    eventDidMount: (evt:CalendarViewEvent) => {
      const { el, event } = evt;
      const td = document.createElement('td');
      const anchor = document.createElement('a');
      anchor.title = 'Delete';
      anchor.href = '#';
      anchor.classList.add('fc-list-day-side-text', 'op-non-working-days-list--delete-icon');
      anchor.appendChild(opIconElement('icon', 'icon-delete'));

      anchor.addEventListener('click', (clickEvent:Event) => {
        clickEvent.preventDefault();

        this.markNonWorkingDayForRemoval(event.id);
        event.remove();
        this.cdRef.detectChanges();
      });
      td.appendChild(anchor);
      el.appendChild(td);
    },
    noEventsContent: { html: `<table class="fc-list-table"><tbody><th><div class="fc-list-day-cushion"><a class="fc-list-day-text">${this.text.empty_state_header}</a></div></th><tr class="fc-event"><td>${this.text.empty_state_description}</td></tr></tbody></table>` },

  };

  constructor() {
    populateInputsFromDataset(this);
  }

  private markNonWorkingDayForRemoval(date:string):void {
    this.nonWorkingDays = this.nonWorkingDays.map((item) => {
      if (item.date === date) {
        return { ...item, _destroy: true };
      }

      return item;
    });
  }

  ngOnInit():void {
    this
      .modifiedNonWorkingDays
      .forEach((el) => {
        this.nonWorkingDays.push({ ...el });
      });
    this.cdRef.detectChanges();
  }

  // Initializes nonWorkingDays from the API
  public calendarEventsFunction(
    fetchInfo:EventSourceFuncArg,
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:Error) => void,
  ):void|PromiseLike<EventInput[]> {
    this.dayService.requireNonWorkingYear$(fetchInfo.start)
      .subscribe(
        (days:IDay[]) => {
          this.nonWorkingDays = _
            .uniqBy([...this.nonWorkingDays, ...days], (el) => el.date)
            .filter((el:INonWorkingDay) => !this.nonWorkingDays.find((existing) => existing.id === el.id && existing._destroy));
          this.originalNonWorkingDays = [...this.nonWorkingDays];
          const events = this.mapToCalendarEvents(this.nonWorkingDays);
          successCallback(events);
          this.cdRef.detectChanges();
        },
        failureCallback,
      );
  }

  private mapToCalendarEvents(nonWorkingDays:INonWorkingDay[]) {
    return nonWorkingDays
      .filter((nwd) => nwd._destroy !== true)
      .map((nwd:IDay) => ({
        title: nwd.name,
        start: nwd.date,
        id: nwd.date,
      }));
  }

  public addNonWorkingDay(date:string):void {
    const name = this.selectedNonWorkingDayName;
    this.selectedNonWorkingDayName = '';

    if (!date || date === '' || !name || name === '') {
      return;
    }

    const day = {
      start: date,
      id: null,
      name,
      date,
      title: name,
    } as INonWorkingDay;

    const api = this.ucCalendar.getApi();

    if (api.getEventById(date)) {
      this.toast.addError(this.text.already_added_error);
      return;
    }

    this.nonWorkingDays = [...this.nonWorkingDays, day];
    api.addEvent({ ...day, id: date });
  }

}
