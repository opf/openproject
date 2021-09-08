import { NotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';

export interface DailyRemindersSettings {
  enabled:boolean;
  times:string[];
}
export interface ImmediateRemindersSettings {
  mentioned:boolean;
}

export interface UserPreferencesModel {
  autoHidePopups:boolean;
  commentSortDescending:boolean;
  hideMail:boolean;
  timeZone:string|null;
  warnOnLeavingUnsaved:boolean;
  notifications:NotificationSetting[];
  dailyReminders:DailyRemindersSettings;
  immediateReminders:ImmediateRemindersSettings;
}
