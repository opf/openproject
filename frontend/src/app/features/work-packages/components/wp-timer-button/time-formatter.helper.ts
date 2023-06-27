import * as moment from 'moment/moment';
import { pad } from 'core-app/features/work-packages/components/wp-timer-button/wp-timer-button.component';

export function formatElapsedTime(startTime:string):string {
  const start = moment(startTime);
  const now = moment();
  const offset = moment(now).diff(start, 'seconds');

  const seconds = pad(offset % 60);
  const minutes = pad(parseInt((offset / 60).toString(), 10) % 60);
  const hours = pad(parseInt((offset / 3600).toString(), 10));

  return `${hours}:${minutes}:${seconds}`;
}
