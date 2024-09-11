import { Controller } from '@hotwired/stimulus';
import { FrameElement } from '@hotwired/turbo';

export default class JobStatusPollingController extends Controller<HTMLElement> {
  static targets = ['finished', 'download', 'redirect', 'indicator', 'frame'];
  static values = { backOnClose: { type: Boolean, default: false } };

  declare readonly backOnCloseValue:boolean;
  declare readonly indicatorTarget:HTMLElement;
  declare readonly frameTarget:FrameElement;

  interval:ReturnType<typeof setInterval>;
  userInteraction:boolean = false;

  connect() {
    this.interval = setInterval(() => this.frameTarget.reload(), 2000);
  }

  disconnect() {
    this.stopPolling();
    if (this.backOnCloseValue && !this.userInteraction) {
      window.history.back();
    }
  }

  finishedTargetConnected() {
    this.stopPolling();
    this.hideProgressIndicator();
  }

  stopPolling() {
    clearInterval(this.interval);
  }

  hideProgressIndicator() {
    this.indicatorTarget.remove();
  }

  downloadTargetConnected(element:HTMLLinkElement) {
    setTimeout(() => element.click(), 50);
  }

  redirectClick(_:Event) {
    this.userInteraction = true;
  }

  redirectTargetConnected(element:HTMLLinkElement) {
    setTimeout(() => {
      this.userInteraction = true;
      window.location.href = element.href;
    }, 2000);
  }
}
