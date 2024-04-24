import { INotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';

export interface DailyRemindersSettings {
  enabled:boolean;
  times:string[];
}
export interface PauseRemindersSettings {
  enabled:boolean;
  firstDay?:string;
  lastDay?:string;
}
export interface ImmediateRemindersSettings {
  mentioned:boolean;
}

export interface IUserPreference {
  autoHidePopups:boolean;
  commentSortDescending:boolean;
  hideMail:boolean;
  timeZone:string|null;
  warnOnLeavingUnsaved:boolean;
  workdays:number[];
  notifications:INotificationSetting[];
  dailyReminders:DailyRemindersSettings;
  immediateReminders:ImmediateRemindersSettings;
  pauseReminders:Partial<PauseRemindersSettings>;
}
