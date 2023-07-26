import { Controller } from '@hotwired/stimulus';

export default class ExpandableSideMenuController extends Controller {
  static targets = [
    'indicator',
    'container',
  ];

  declare readonly indicatorTarget:HTMLElement;
  declare readonly containerTarget:HTMLElement;

  toggleContainer() {
    if (this.isExpanded()) {
      this.collapse();
    } else {
      this.expand();
    }
  }

  private isExpanded() {
    return this.indicatorTarget.classList.contains('icon-arrow-up1');
  }

  private expand() {
    this.containerTarget.classList.replace('op-sidemenu--items_collapsed', 'op-sidemenu--items');
    this.indicatorTarget.classList.replace('icon-arrow-down1', 'icon-arrow-up1');
  }

  private collapse() {
    this.containerTarget.classList.replace('op-sidemenu--items', 'op-sidemenu--items_collapsed');
    this.indicatorTarget.classList.replace('icon-arrow-up1', 'icon-arrow-down1');
  }
}
