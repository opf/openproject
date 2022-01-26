import {
  Component,
  HostBinding,
  Input,
  OnDestroy,
} from '@angular/core';

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

    /* We have to set these listeners next tick, because they're so far up the tree.
     * If the open value was set because of a click listener in the trigger slot,
     * that event would reach the event listener added here and close the modal right away.
     */
    setTimeout(() => {
      if (this._open) {
        document.body.addEventListener('click', this.closeEventListener);
      } else {
        document.body.removeEventListener('click', this.closeEventListener);
      }
    });
  }

  public get open():boolean {
    return this._open;
  }

  private closeEventListener = this.close.bind(this);

  private close():void {
    this.open = false;
  }

  public ngOnDestroy():void {
    document.body.removeEventListener('click', this.closeEventListener);
  }
}

