import { ApplicationController } from 'stimulus-use';

export const SUCCESS_AUTOHIDE_TIMEOUT = 5000;

export default class FlashController extends ApplicationController {
  static values = {
    autohide: Boolean,
  };

  declare autohideValue:boolean;

  static targets = [
    'item',
  ];

  declare readonly itemTargets:HTMLElement;

  itemTargetConnected(element:HTMLElement) {
    const autohide = element.dataset.autohide === 'true';
    if (this.autohideValue && autohide) {
      setTimeout(() => element.remove(), SUCCESS_AUTOHIDE_TIMEOUT);
    }
  }
}
