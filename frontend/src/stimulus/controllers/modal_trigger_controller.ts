import { Controller } from '@hotwired/stimulus';
import ClickEvent = JQuery.ClickEvent;
import { FrameElement } from '@hotwired/turbo';

export class ModalTriggerController extends Controller {
  open(evt:ClickEvent) {
    const frame = document.getElementById('modal') as FrameElement;
    frame.src = evt.target.dataset.modalFrame;
    frame.reload();
  }
}
