import { Controller } from '@hotwired/stimulus';
import * as moment from 'moment';

export default class MyTimersController extends Controller {
  static values = {
    start: String,
  };

  static targets = [
    'elapsedTime',
  ];

  declare readonly elapsedTimeTarget:HTMLElement;
  declare readonly startValue:string;

  connect() {
    super.connect();
    this.elapsedTimeTarget.textContent = 'Loading timer...';
    this.timer(this.startValue);
  }

  pad(val:number):string {
    return val > 9 ? val.toString() : `0${val}`;
  }

  timer(value:string|null|undefined) {
    const start = moment(value as string);
    const now = moment();
    let offset = moment(now).diff(start, 'seconds');
    let seconds = '';
    let hours = '';
    let minutes = '';
    setInterval(() => {
      /* eslint-disable no-plusplus */
      seconds=this.pad(++offset%60);
      minutes=this.pad(parseInt((offset / 60).toString(), 10) % 60);
      hours = this.pad(parseInt((offset / 3600).toString(), 10));

      this.elapsedTimeTarget.textContent = `${hours}:${minutes}:${seconds}`;
    }, 1000);
  }
}
