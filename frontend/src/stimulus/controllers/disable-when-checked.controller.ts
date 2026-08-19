import { ApplicationController } from 'stimulus-use';

export default class OpDisableWhenCheckedController extends ApplicationController {
  static targets = ['cause', 'effect'];

  static values = {
    reversed: Boolean,
  };

  declare reversedValue:boolean;

  declare readonly hasReversedValue:boolean;

  declare readonly effectTargets:HTMLInputElement[];

  private boundListener = this.toggleDisabled.bind(this);

  causeTargetConnected(target:HTMLElement) {
    target.addEventListener('change', this.boundListener);
  }

  causeTargetDisconnected(target:HTMLElement) {
    target.removeEventListener('change', this.boundListener);
  }

  private toggleDisabled(evt:InputEvent):void {
    const input = evt.target as HTMLInputElement;
    const checked = input.checked;
    const targetName = input.dataset.targetName;

    const affectedTargets = targetName
      ? this.effectTargets.filter((el) => targetName === el.dataset.targetName)
      : this.effectTargets;

    affectedTargets.forEach((el) => {
      el.disabled = (this.hasReversedValue && this.reversedValue) ? !checked : checked;
    });

    // specific handling for select options
    affectedTargets
      .filter((el) => el instanceof HTMLOptGroupElement || el instanceof HTMLOptionElement)
      .map((option) => option.closest('select')!)
      .filter((select, index, self) => self.indexOf(select) === index) // unique
      .forEach((select) => {
        if (select.options[select.selectedIndex]?.disabled) {
          select.value = '';
        }
      });
  }
}
