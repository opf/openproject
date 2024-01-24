import { action, props } from 'ts-action';

export const shareModalUpdated = action(
  '[Sharing] Share modal closed or updated',
  props<{ workPackageId:string }>(),
);
