import { NotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';

export interface UserPreferencesModel {
  autoHidePopups:boolean;
  commentSortDescending:boolean;
  hideMail:boolean;
  timeZone:string|null;
  warnOnLeavingUnsaved:boolean;
  notifications:NotificationSetting[];
}
