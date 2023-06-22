import { Controller } from '@hotwired/stimulus';

export default class MyTimersController extends Controller {
  static targets = [
    'elapsedTime',
  ];

  declare readonly elapsedTimeTarget:HTMLElement;
  
  connect() {
    super.connect();

    this.elapsedTimeTarget.textContent = 'Hello from stimulus';
  }
}
