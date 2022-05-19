import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import {
  UntypedFormGroup,
  FormGroupDirective,
} from '@angular/forms';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  map,
  startWith,
} from 'rxjs/operators';
import { Observable } from 'rxjs';

@Component({
  selector: 'op-pause-reminders',
  templateUrl: './pause-reminders.component.html',
  styleUrls: ['./pause-reminders.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PauseRemindersComponent implements OnInit {
  form:UntypedFormGroup;

  selectedDates$:Observable<[string, string]>;

  enabled$:Observable<boolean>;

  text = {
    label: this.I18n.t('js.reminders.settings.pause.label'),
    date_placeholder: this.I18n.t('js.placeholders.date'),
    first_day: this.I18n.t('js.reminders.settings.pause.first_day'),
    last_day: this.I18n.t('js.reminders.settings.pause.first_day'),
  };

  constructor(
    private I18n:I18nService,
    private rootFormGroup:FormGroupDirective,
  ) {
  }

  ngOnInit():void {
    this.form = this.rootFormGroup.control.get('pauseReminders') as UntypedFormGroup;
    this.selectedDates$ = this
      .form
      .valueChanges
      .pipe(
        startWith(this.form.value),
        map((form:{ firstDay:string, lastDay:string }) => [form.firstDay, form.lastDay]),
      );

    this.enabled$ = this
      .form
      .valueChanges
      .pipe(
        startWith(this.form.value),
        map((form:{ enabled:boolean }) => form.enabled),
      );
  }

  setDates($event:[string, string]):void {
    const [firstDay, lastDay] = $event;
    this.form.patchValue({
      firstDay,
      lastDay,
    });
  }
}
