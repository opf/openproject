import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { ImmediateRemindersSettings } from 'core-app/features/user-preferences/state/user-preferences.model';

@Component({
  selector: 'op-immediate-reminder-settings',
  templateUrl: './immediate-reminder-settings.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ImmediateReminderSettingsComponent {
  immediateReminders$ = this.storeService.query.select('immediateReminders');

  text = {
    mentioned: this.I18n.t('js.reminders.settings.immediate.mentioned'),
  };

  constructor(
    private I18n:I18nService,
    private storeService:UserPreferencesService,
  ) {
  }

  toggleEnabled(key:keyof ImmediateRemindersSettings, enabled:boolean):void {
    this.storeService.store.update(({ immediateReminders }) => (
      {
        immediateReminders: {
          ...immediateReminders,
          [key]: enabled,
        },
      }
    ));
  }
}
