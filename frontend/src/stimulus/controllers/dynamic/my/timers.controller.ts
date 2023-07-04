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


  timer(value:string|null|undefined) {
    const start = moment(value as string);
    const now = moment();
    let offset = moment(now).diff(start, 'seconds');
    setInterval(() => {
      this.elapsedTimeTarget.textContent = moment.utc(now.diff(start, 'seconds')).format("HH:mm:ss")
    }, 1000);
  }
}
