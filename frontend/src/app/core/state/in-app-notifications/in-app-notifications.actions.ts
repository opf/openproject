import { ID } from '@datorama/akita';
import {
  action,
  props,
} from 'ts-action';

export const markNotificationsAsRead = action(
  '[IAN] Mark notifications as read',
  props<{ origin:string, notifications:ID[] }>(),
);

export const notificationsMarkedRead = action(
  '[IAN] Notifications were marked as read',
  props<{ origin:string, notifications:ID[] }>(),
);

export const notificationCountIncreased = action(
  '[IAN] The backend sent a notification count that was higher than the last known',
  props<{ origin:string, count:number }>(),
);

export const centerUpdatedInPlace = action(
  '[IAN] The notification center updated the notification list without a full page refresh',
  props<{ origin:string }>(),
);
