import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['items'];

  itemTargets:HTMLElement[];

  initialize() {
  }

}
