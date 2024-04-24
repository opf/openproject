import { ApplicationController } from 'stimulus-use';

export default class PrintController extends ApplicationController {
  triggerPrint(evt:MouseEvent) {
    evt.preventDefault();
    window.print();
  }
}
