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
  personalReminder:boolean;
}

export type ITypeQuickFilterView = 'boards'|'work_packages'|'gantt'|'kanban';

export interface ITypeQuickFilterSettings {
  boards?:string[]|null;
  work_packages?:string[]|null;
  gantt?:string[]|null;
  kanban?:string[]|null;
}

export interface IUserPreference {
  autoHidePopups:boolean;
  commentSortDescending:boolean;
  disableKeyboardShortcuts:boolean;
  timeZone:string|null;
  warnOnLeavingUnsaved:boolean;
  workdays:number[];
  notifications:INotificationSetting[];
  dailyReminders:DailyRemindersSettings;
  immediateReminders:ImmediateRemindersSettings;
  pauseReminders:Partial<PauseRemindersSettings>;
  typeQuickFilter?:ITypeQuickFilterSettings|null;
}
