import { Component, Input, OnInit } from "@angular/core";
import { ChangeDetectionStrategy } from "@angular/core";
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';

@Component({
  selector: 'op-reminder-settings-daily-time',
  templateUrl: './reminder-settings-daily-time.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ReminderSettingsDailyTimeComponent implements OnInit {
  public dailyReminderTimes = ["08:00", "12:00", "16:00"]

  text = {
    label: (counter:number):string => this.I18n.t('js.reminders.settings.daily.label', { counter: counter }),
  };

  constructor(
    private I18n:I18nService,
    private store:UserPreferencesStore,
  ) {
  }

  ngOnInit():void {

  }

  public saveChanges():void {
  }
}
