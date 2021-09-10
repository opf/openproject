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
