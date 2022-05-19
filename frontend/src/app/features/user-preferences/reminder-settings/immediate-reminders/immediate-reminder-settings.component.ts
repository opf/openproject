import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import {
  UntypedFormGroup,
  FormGroupDirective,
} from '@angular/forms';

@Component({
  selector: 'op-immediate-reminder-settings',
  templateUrl: './immediate-reminder-settings.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ImmediateReminderSettingsComponent implements OnInit {
  form:UntypedFormGroup;

  text = {
    title: this.I18n.t('js.reminders.settings.immediate.title'),
    explanation: this.I18n.t('js.reminders.settings.immediate.explanation'),
    mentioned: this.I18n.t('js.reminders.settings.immediate.mentioned'),
  };

  constructor(
    private I18n:I18nService,
    private storeService:UserPreferencesService,
    private rootFormGroup:FormGroupDirective,
  ) {
  }

  ngOnInit():void {
    this.form = this.rootFormGroup.control.get('immediateReminders') as UntypedFormGroup;
  }
}
