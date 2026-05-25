import { Controller } from '@hotwired/stimulus';

const DISMISSED_KEY = 'mngt_notif_prompt_dismissed_v1';

export default class NotifPromptController extends Controller {
  static targets = ['banner', 'stateDefault', 'stateDenied', 'btnEnable'];

  declare bannerTarget: HTMLElement;
  declare stateDefaultTarget: HTMLElement;
  declare stateDeniedTarget: HTMLElement;
  declare btnEnableTarget: HTMLElement;

  connect() {
    if (!('Notification' in window)) return;
    if (Notification.permission === 'granted') return;
    if (localStorage.getItem(DISMISSED_KEY)) return;
    this.render();
  }

  async enable() {
    const result = await Notification.requestPermission();
    if (result === 'granted') {
      document.dispatchEvent(new CustomEvent('mngt:push-subscribe'));
      this.hide();
    } else {
      this.render();
    }
  }

  check() {
    if (Notification.permission === 'granted') {
      this.hide();
    }
  }

  dismiss() {
    localStorage.setItem(DISMISSED_KEY, '1');
    this.hide();
  }

  private render() {
    const denied = Notification.permission === 'denied';
    this.stateDefaultTarget.hidden = denied;
    this.stateDeniedTarget.hidden  = !denied;
    this.bannerTarget.hidden       = false;
  }

  private hide() {
    this.bannerTarget.hidden = true;
  }
}
