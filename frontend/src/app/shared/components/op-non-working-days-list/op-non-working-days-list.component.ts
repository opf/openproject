import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
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
import { CalendarOptions, EventInput, EventSourceFuncArg } from '@fullcalendar/core';
import listPlugin from '@fullcalendar/list';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { CalendarViewEvent } from 'core-app/features/calendar/op-work-packages-calendar.service';
import { opIconElement } from 'core-app/shared/helpers/op-icon-builder';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { ConfirmDialogOptions } from '../modals/confirm-dialog/confirm-dialog.modal';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import * as moment from 'moment-timezone';
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
})
export class OpNonWorkingDaysListComponent implements OnInit, AfterViewInit {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @HostBinding('class.op-non-working-days-list') className = true;

  @Input() public modifiedNonWorkingDays:INonWorkingDay[] = [];

  text = {
    empty_state_header: this.I18n.t('js.admin.working_days.calendar.empty_state_header'),
    empty_state_description: this.I18n.t('js.admin.working_days.calendar.empty_state_description'),
    already_added_error: this.I18n.t('js.admin.working_days.already_added_error'),
    new_date: this.I18n.t('js.admin.working_days.calendar.new_date'),
    add_non_working_day: this.I18n.t('js.admin.working_days.add_non_working_day'),
    change_description: this.I18n.t('js.admin.working_days.change_description'),
    warning: this.I18n.t('js.admin.working_days.warning'),
    change_button: this.I18n.t('js.admin.working_days.change_button'),
    change_title: this.I18n.t('js.admin.working_days.change_title'),
    removed_title: this.I18n.t('js.admin.working_days.removed_title'),
    non_working_day_name: this.I18n.t('js.modals.label_name'),
    add: this.I18n.t('js.button_add'),
  };

  form_submitted = false;

  originalNonWorkingDays:INonWorkingDay[] = [];
  nonWorkingDays:INonWorkingDay[] = [];

  originalWorkingDays:string[] = [];

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

      anchor.addEventListener('click', () => {
        // Create 4 hidden inputs(id, name, date, _destroy) for the deleted NWD
        this.nonWorkingDays = this.nonWorkingDays.map((item) => {
          if (item.date === event.id) {
            return { ...item, _destroy: true };
          }

          return item;
        });
        event.remove();
        this.cdRef.detectChanges();
      });
      td.appendChild(anchor);
      el.appendChild(td);
    },
    noEventsContent: { html: `<table class="fc-list-table"><tbody><th><div class="fc-list-day-cushion"><a class="fc-list-day-text">${this.text.empty_state_header}</a></div></th><tr class="fc-event"><td>${this.text.empty_state_description}</td></tr></tbody></table>` },

  };

  constructor(
    readonly elementRef:ElementRef<HTMLElement>,
    protected I18n:I18nService,
    readonly bannersService:BannersService,
    readonly opModalService:OpModalService,
    readonly injector:Injector,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly dayService:DayResourceService,
    readonly confirmDialogService:ConfirmDialogService,
    readonly toast:ToastService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    populateInputsFromDataset(this);
    this.listenToFormSubmit();
  }

  private listenToFormSubmit() {
    const form = this.elementRef.nativeElement.closest('form') as HTMLFormElement;
    form.addEventListener('submit', (evt:Event) => {
      if (!this.form_submitted
        && (this.nonWorkingDaysModified() || this.workingDaysModified())) {
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
          refreshOnCancel: true,
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
    this
      .modifiedNonWorkingDays
      .forEach((el) => {
        this.nonWorkingDays.push({ ...el });
      });
    this.cdRef.detectChanges();
  }

  ngAfterViewInit():void {
    const form = this.elementRef.nativeElement.closest('form') as HTMLFormElement;
    const workingDayCheckboxes = Array.from(form.querySelectorAll('input[name="settings[working_days][]"]'));
    workingDayCheckboxes.forEach((checkbox:HTMLInputElement) => {
      if (checkbox.checked) {
        this.originalWorkingDays.push(checkbox.value);
      }
    });
  }

  public get removedNonWorkingDays():string[] {
    return this
      .nonWorkingDays
      .filter((el) => el._destroy)
      .map((el) => moment(el.date).format('MMMM DD, YYYY'));
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

  private get workingDays():string[] {
    const workingDays:string[] = [];

    const form = this.elementRef.nativeElement.closest('form') as HTMLFormElement;
    const workingDayCheckboxes = Array.from(form.querySelectorAll('input[name="settings[working_days][]"]'));
    workingDayCheckboxes.forEach((checkbox:HTMLInputElement) => {
      if (checkbox.checked) {
        workingDays.push(checkbox.value);
      }
    });

    return workingDays;
  }

  private nonWorkingDaysModified():boolean {
    return this.removedNonWorkingDays.length > 0
      || this.modifiedNonWorkingDays.length > 0
      || this.nonWorkingDays.length > this.originalNonWorkingDays.length;
  }

  private workingDaysModified():boolean {
    return _.difference(this.workingDays, this.originalWorkingDays).length > 0
      || _.difference(this.originalWorkingDays, this.workingDays).length > 0;
  }
}
