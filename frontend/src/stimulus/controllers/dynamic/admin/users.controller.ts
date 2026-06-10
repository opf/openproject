import { Controller } from '@hotwired/stimulus';
import { toggleEnabled } from 'core-app/shared/helpers/dom-helpers';

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

  declare readonly hasAuthSourceFieldsTarget:boolean;

  toggleAuthenticationFields(evt:{ target:HTMLSelectElement }):void {
    this.passwordAuthSelectedValue = evt.target.value === '';
  }

  private passwordAuthSelectedValueChanged() {
    if (this.hasPasswordFieldsTarget) {
      this.toggleHiddenAndDisabled(this.passwordFieldsTarget, !this.passwordAuthSelectedValue);
    }
    if (this.hasAuthSourceFieldsTarget) {
      this.toggleHiddenAndDisabled(this.authSourceFieldsTarget, this.passwordAuthSelectedValue);
    }
  }

  private toggleHiddenAndDisabled(target:HTMLElement, hiddenAndDisabled:boolean) {
    toggleEnabled(target, !hiddenAndDisabled, true);
    target.querySelectorAll('input')
      .forEach((el:HTMLInputElement) => toggleEnabled(el, !hiddenAndDisabled));
  }
}
