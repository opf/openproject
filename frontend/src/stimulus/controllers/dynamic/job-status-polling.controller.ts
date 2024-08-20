import { Controller } from '@hotwired/stimulus';
import { FrameElement } from '@hotwired/turbo';

export default class JobStatusPollingController extends Controller<FrameElement> {
  static targets = ['finished', 'download', 'redirect'];
  static values = { backOnClose: { type: Boolean, default: false } };

  declare readonly backOnCloseValue:boolean;

  interval:ReturnType<typeof setInterval>;

  connect() {
    this.interval = setInterval(() => this.element.reload(), 2000);
  }

  disconnect() {
    this.finishedTargetConnected();
    if (this.backOnCloseValue) {
      window.history.back();
    }
  }

  finishedTargetConnected() {
    clearInterval(this.interval);
  }

  downloadTargetConnected(element:HTMLLinkElement) {
    setTimeout(() => element.click(), 50);
  }

  redirectTargetConnected(element:HTMLLinkElement) {
    setTimeout(() => { window.location.href = element.href; }, 2000);
  }
}
