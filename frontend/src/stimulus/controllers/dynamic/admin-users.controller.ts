import { Controller } from '@hotwired/stimulus';

export default class AdminUsersController extends Controller {
  static targets = ['passwordFields'];

  declare readonly passwordFieldsTarget:HTMLElement;

  togglePasswordFields(evt:{ target:HTMLSelectElement }):void {
    const selected = evt.target.value;

    this.passwordFieldsTarget.hidden = selected !== '';
    this.passwordFieldsTarget
      .querySelectorAll('input[type="password"]')
      .forEach((el:HTMLInputElement) => {
        el.disabled = selected !== '';
      });
  }
}
