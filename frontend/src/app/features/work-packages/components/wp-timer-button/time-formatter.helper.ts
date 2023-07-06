import * as moment from 'moment/moment';

export function formatElapsedTime(startTime:string):string {
  const start = moment(startTime);
  const now = moment();
  const offset = moment(now).diff(start);

  return moment.utc(offset).format('HH:mm:ss');
}
