import { Controller } from '@hotwired/stimulus';

export default class AddWidgetsController extends Controller {
  private addWidget():void {
    document.dispatchEvent(
      new CustomEvent('overview:addWidget'),
    );
  }
}
