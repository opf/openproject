import { Controller } from '@hotwired/stimulus';

export default class OpenidConnectProvidersController extends Controller {
  static targets = [
    'azureForm',
  ];

  declare readonly azureFormTarget:HTMLElement;

  public updateTypeForm(evt:InputEvent) {
    const name = (evt.target as HTMLInputElement).value;
    this.azureFormTarget.hidden = name !== 'azure';
    this
      .azureFormTarget
      .querySelectorAll('input')
      .forEach((el) => (el.disabled = this.azureFormTarget.hidden));
  }
}
