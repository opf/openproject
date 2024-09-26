import { ApplicationController } from 'stimulus-use';

export default class OpShowWhenValueSelectedController extends ApplicationController {
  static targets = ['cause', 'effect'];

  declare readonly effectTargets:HTMLInputElement[];

  causeTargetConnected(target:HTMLElement) {
    target.addEventListener('change', this.toggleDisabled.bind(this));
  }

  causeTargetDisconnected(target:HTMLElement) {
    target.removeEventListener('change', this.toggleDisabled.bind(this));
  }

  private toggleDisabled(evt:InputEvent):void {
    const value = (evt.target as HTMLInputElement).value;
    this.effectTargets.forEach((el) => {
      el.hidden = !(el.dataset.value === value);
    });
  }
}
