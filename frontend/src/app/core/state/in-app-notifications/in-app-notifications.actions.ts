import { createAction, props } from '@datorama/akita-ng-effects';
import { ID } from '@datorama/akita';

export const markNotificationsAsRead = createAction(
  '[IAN] Mark notifications as read',
  props<{ caller:{ id:string }, notifications:ID[] }>(),
);

export const notificationsMarkedRead = createAction(
  '[IAN] Notifications were marked as read',
  props<{ caller:{ id:string }, notifications:ID[] }>(),
);
