import {
  Component,
  HostBinding,
  Input,
  Output,
  EventEmitter,
  OnDestroy,
} from '@angular/core';

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

  @Input('open')
  public set open(value:boolean) {
    this._open = value;

    if (this._open) {
      /* We have to set these listeners next tick, because they're so far up the tree.
       * If the open value was set because of a click listener in the trigger slot,
       * that event would reach the event listener added here and close the modal right away.
       */
      setTimeout(() => {
        document.body.addEventListener('click', this.closeEventListener);
      })
    } else {
      document.body.removeEventListener('click', this.closeEventListener);
      this.closed.emit();
    }
  }

  public get open():boolean {
    return this._open;
  }

  @Input('alignment') public alignment:SpotDropModalAlignmentOption = SpotDropModalAlignmentOption.BottomCenter;

  get alignmentClass() {
    return `spot-drop-modal--body_${this.alignment}`;
  }

  @Output() closed = new EventEmitter<void>();

  private closeEventListener = this.close.bind(this);

  private close():void {
    this.open = false;
  }

  public ngOnDestroy():void {
    document.body.removeEventListener('click', this.closeEventListener);
  }
}

