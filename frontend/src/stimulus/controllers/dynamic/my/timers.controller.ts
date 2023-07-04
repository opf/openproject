import { Controller } from '@hotwired/stimulus';
import { formatElapsedTime } from 'core-app/features/work-packages/components/wp-timer-button/time-formatter.helper';

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
    setInterval(() => {
      this.elapsedTimeTarget.textContent = formatElapsedTime(value as string);
    }, 1000);
  }
}
