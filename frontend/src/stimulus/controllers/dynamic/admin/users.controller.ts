import { Controller } from '@hotwired/stimulus';

export default class UsersController extends Controller {
  static targets = [
    'passwordFields',
    'authSourceFields',
  ];

  static values = {
    passwordAuthSelected: Boolean,
  };

  declare passwordAuthSelectedValue:boolean;

  declare readonly passwordFieldsTarget:HTMLElement;

  declare readonly hasPasswordFieldsTarget:boolean;

  declare readonly authSourceFieldsTarget:HTMLElement;

  toggleAuthenticationFields(evt:{ target:HTMLSelectElement }):void {
    this.passwordAuthSelectedValue = evt.target.value === '';
  }

  private passwordAuthSelectedValueChanged() {
    if (this.hasPasswordFieldsTarget) {
      this.toggleHiddenAndDisabled(this.passwordFieldsTarget, !this.passwordAuthSelectedValue);
    }
    this.toggleHiddenAndDisabled(this.authSourceFieldsTarget, this.passwordAuthSelectedValue);
  }

  private toggleHiddenAndDisabled(target:HTMLElement, hiddenAndDisabled:boolean) {
    target.hidden = hiddenAndDisabled;
    target.querySelectorAll('input')
      .forEach((el:HTMLInputElement) => {
        el.disabled = hiddenAndDisabled;
      });
  }
}
