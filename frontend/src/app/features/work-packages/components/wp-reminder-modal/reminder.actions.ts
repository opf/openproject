import { action, props } from 'ts-action';

export const reminderModalUpdated = action(
  '[Reminder] Reminder modal closed or updated',
  props<{ workPackageId:string }>(),
);
