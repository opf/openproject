import { Controller } from '@hotwired/stimulus';

export default class HelpMenuController extends Controller {
  static targets = [
    'additionalResourcesDropdown',
    'additionalResourcesContent',
    'additionalResourcesDropdownHandle',
  ];

  declare readonly additionalResourcesDropdownTarget:HTMLElement;
  declare readonly additionalResourcesContentTarget:HTMLElement;
  declare readonly additionalResourcesDropdownHandleTarget:HTMLElement;

  private toggleMenuState() {
    this.additionalResourcesContentTarget.classList.toggle('op-menu--hide');
    this.additionalResourcesDropdownHandleTarget.classList.toggle('icon-arrow-down1');
    this.additionalResourcesDropdownHandleTarget.classList.toggle('icon-arrow-up1');
  }
}
