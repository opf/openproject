import {
  Component,
  HostBinding,
  Input,
  Output,
  EventEmitter,
  OnDestroy,
} from '@angular/core';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import SpotDropAlignmentOption from '../../drop-alignment-options';

@Component({
  selector: 'spot-drop-modal',
  templateUrl: './drop-modal.component.html',
})
export class SpotDropModalComponent implements OnDestroy {
  @HostBinding('class.spot-drop-modal') public className = true;

  @Output() closed = new EventEmitter<void>();

  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomLeft;

  public _open = false;

  @Input('open')
  @HostBinding('class.spot-drop-modal_opened')
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

  public text = {
    close: this.i18n.t('js.spot.drop_modal.close'),
  };

  constructor(readonly i18n:I18nService) {}

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

  private closeEventListener = this.close.bind(this) as () => void;

  private onEscape = (evt:KeyboardEvent) => {
    if (evt.keyCode === KeyCodes.ESCAPE) {
      this.close();
    }
  };

  private escapeListener = this.onEscape.bind(this) as () => void;
}
