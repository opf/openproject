import { ApplicationController } from 'stimulus-use';

export default class OpZenModeController extends ApplicationController {
  inZenMode = false;

  private boundHandler = this.fullscreenChangeEventHandler.bind(this);

  connect() {
    document.addEventListener('fullscreenchange', this.boundHandler);
  }

  disconnect() {
    super.disconnect();
    document.removeEventListener('fullscreenchange', this.boundHandler);
  }

  fullscreenChangeEventHandler() {
    this.inZenMode = !this.inZenMode;
    this.dispatchZenModeStatus();
  }

  dispatchZenModeStatus() {
    // Create a new custom event
    const event = new CustomEvent('zenModeToggled', {
      detail: {
        active: this.inZenMode,
      },
    });
    // Dispatch the custom event
    window.dispatchEvent(event);
  }

  deactivateZenMode() {
    if (document.exitFullscreen) {
      void document.exitFullscreen();
    }
  }

  activateZenMode() {
    if (document.documentElement.requestFullscreen) {
      void document.documentElement.requestFullscreen();
    }
  }

  public performAction() {
    if (this.inZenMode) {
      this.deactivateZenMode();
    } else {
      this.activateZenMode();
    }
  }
}
