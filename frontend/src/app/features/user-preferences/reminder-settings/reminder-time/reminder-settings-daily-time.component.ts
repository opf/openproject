import { Component, ChangeDetectionStrategy } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

interface ReminderTime {
  label:string
  time:string
  active:boolean,
  suggested:boolean
}

@Component({
  selector: 'op-reminder-settings-daily-time',
  templateUrl: './reminder-settings-daily-time.component.html',
  styleUrls: ['./reminder-settings-daily-time.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ReminderSettingsDailyTimeComponent {
  public selectedTimes:Array<ReminderTime> = [];

  public availableTimes:Array<ReminderTime> = [];

  public enabled = true;

  text = {
    timeLabel: (counter:number):string => this.I18n.t('js.reminders.settings.daily.time_label', { counter }),
    addTime: this.I18n.t('js.reminders.settings.daily.add_time'),
    enable: this.I18n.t('js.reminders.settings.daily.enable'),
  };

  constructor(
    private I18n:I18nService,
  ) {
    this.setupAvailableTimes();
    this.setupSelectedTimes();
  }

  get nonAddable():boolean {
    return !this.enabled || this.selectedTimes.length === this.availableTimes.length;
  }

  indexTracker(index:number):number {
    return index;
  }

  addTime():void {
    if (this.nonAddable) {
      return;
    }

    const time = this.firstAvailableSuggested() || this.firstAfterSelected();

    if (time) {
      this
        .selectedTimes
        .push(time);
    }
  }

  isOptionDisabled(time:ReminderTime, self:ReminderTime):boolean {
    return time !== self && this.selectedTimes.includes(time);
  }

  get isActiveDisabled():boolean {
    return !this.enabled || this.selectedTimes.length === 1;
  }

  get isRemovable():boolean {
    return this.enabled && this.selectedTimes.length > 1;
  }

  removeTime(index:number):void {
    this.selectedTimes.splice(index, 1);

    if (this.selectedTimes.length === 1) {
      this.selectedTimes[0].active = true;
    }
  }

  private setupAvailableTimes() {
    const date = new Date();

    for (let i = 0; i < 24; i++) {
      date.setTime(1000 * 60 * 60 * (i - 1));
      this.availableTimes.push(this.toAvailableTime(date));
    }
  }

  private setupSelectedTimes() {
    // TODO: fetch selectedTimes from user preferences
    this.selectedTimes = [this.availableTimes[8]];
  }

  private firstAvailableSuggested() {
    return this.availableTimes.filter((v) => v.suggested && !this.selectedTimes.includes(v))[0];
  }

  private firstAfterSelected() {
    const indexLastSelected = this.availableTimes.indexOf(this.selectedTimes[this.selectedTimes.length - 1]);

    for (let i = indexLastSelected; i < 24 + indexLastSelected; i++) {
      if (!this.selectedTimes.includes(this.availableTimes[i % 24])) {
        return this.availableTimes[i % 24];
      }
    }

    return null;
  }

  private toAvailableTime(date:Date) {
    const time = date.toLocaleTimeString('en-US', { hour12: false, hour: 'numeric', minute: 'numeric' });

    return {
      label: this.I18n.toTime('time.formats.time', date),
      time,
      active: true,
      suggested: ['08:00', '12:00', '15:00', '18:00'].includes(time),
    };
  }
}
