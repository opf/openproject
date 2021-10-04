import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import {
  FormGroup,
  FormGroupDirective,
} from '@angular/forms';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'op-pause-reminders',
  templateUrl: './pause-reminders.component.html',
  styleUrls: ['./pause-reminders.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PauseRemindersComponent implements OnInit {
  form:FormGroup;

  text = {
    label: this.I18n.t('js.reminders.settings.pause.label'),
    date_placeholder: this.I18n.t('js.placeholders.date'),
  };

  constructor(
    private I18n:I18nService,
    private rootFormGroup:FormGroupDirective,
  ) {
  }

  ngOnInit():void {
    this.form = this.rootFormGroup.control.get('pauseReminders') as FormGroup;
  }
}
