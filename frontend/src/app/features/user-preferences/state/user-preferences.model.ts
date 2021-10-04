import { NotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';

export interface DailyRemindersSettings {
  enabled:boolean;
  times:string[];
}
export interface ImmediateRemindersSettings {
  mentioned:boolean;
}

export interface PauseRemindersSettings {
  enabled:boolean;
  time:string;
}

export interface UserPreferencesModel {
  autoHidePopups:boolean;
  commentSortDescending:boolean;
  hideMail:boolean;
  timeZone:string|null;
  warnOnLeavingUnsaved:boolean;
  workdays:number[];
  notifications:NotificationSetting[];
  dailyReminders:DailyRemindersSettings;
  immediateReminders:ImmediateRemindersSettings;
  pauseReminders:PauseRemindersSettings;
}
