import { ID } from '@datorama/akita';
import {
  action,
  props,
} from 'ts-action';

export const calendarRefreshRequest = action(
  '[Calendar] Refresh calendar page due to external param changes',
  props<{ showLoading:boolean }>(),
);
