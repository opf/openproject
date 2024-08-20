import { Controller } from "@hotwired/stimulus";
import { FrameElement } from '@hotwired/turbo';

export default class JobStatusPollingController extends Controller<FrameElement> {
  static targets = ["finished", "download", "redirect"];

  interval:ReturnType<typeof setInterval>;

  connect() {
    this.interval = setInterval(() => {
        void this.element.reload();
      },
      2000)
  }

  disconnect() {
    this.finishedTargetConnected();
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
