import {
  Component,
  HostBinding,
  Input,
  Output,
  EventEmitter,
  OnDestroy,
} from '@angular/core';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';

enum SpotDropModalAlignmentOption {
  BottomCenter = 'bottom-center',
  BottomLeft = 'bottom-left',
  BottomRight = 'bottom-right',
  TopCenter = 'top-center',
  TopLeft = 'top-left',
  TopRight = 'top-right',
}

@Component({
  selector: 'spot-drop-modal',
  templateUrl: './drop-modal.component.html',
})
export class SpotDropModalComponent implements OnDestroy {
  @HostBinding('class.spot-drop-modal') public className = true;

  @HostBinding('class.spot-drop-modal_opened') public _open = false;

  @Output() closed = new EventEmitter<void>();

  @Input('alignment') public alignment:SpotDropModalAlignmentOption = SpotDropModalAlignmentOption.BottomLeft;

  @Input('open')
  set open(value:boolean) {
    this._open = value;

    if (this._open) {
      /* We have to set these listeners next tick, because they're so far up the tree.
       * If the open value was set because of a click listener in the trigger slot,
       * that event would reach the event listener added here and close the modal right away.
       */
      setTimeout(() => {
        document.body.addEventListener('click', this.closeEventListener);
        document.body.addEventListener('keydown', this.escapeListener);
      });
    } else {
      document.body.removeEventListener('click', this.closeEventListener);
      document.body.removeEventListener('click', this.escapeListener);
      this.closed.emit();
    }
  }

  get open():boolean {
    return this._open;
  }

  get alignmentClass():string {
    return `spot-drop-modal--body_${this.alignment}`;
  }

  close():void {
    this.open = false;
  }

  onBodyClick(e:MouseEvent):void {
    // We stop propagation here so that clicks inside the body do not
    // close the modal when the event reaches the document body
    e.stopPropagation();
  }

  ngOnDestroy():void {
    document.body.removeEventListener('click', this.closeEventListener);
    document.body.removeEventListener('click', this.escapeListener);
  }

  private closeEventListener = this.close.bind(this);

  private escapeListener = (evt:KeyboardEvent) => {
    if (evt.keyCode === KeyCodes.ESCAPE) {
      this.close();
    }
  };
}
