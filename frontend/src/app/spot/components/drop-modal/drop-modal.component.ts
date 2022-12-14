import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  HostBinding,
  Input,
  OnDestroy,
  Output,
} from '@angular/core';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import SpotDropAlignmentOption from '../../drop-alignment-options';
import { findAllFocusableElementsWithin } from 'core-app/shared/helpers/focus-helpers';

@Component({
  selector: 'spot-drop-modal',
  templateUrl: './drop-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SpotDropModalComponent implements OnDestroy {
  @HostBinding('class.spot-drop-modal') public className = true;

  /**
   * The alignment of the drop modal. There are twelve alignments in total. You can check which ones they are
   * from the `SpotDropAlignmentOption` Enum that is available in 'core-app/spot/drop-alignment-options'.
   */
  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomLeft;

  get alignmentClass():string {
    return `spot-drop-modal--body_${this.alignment}`;
  }

  public _open = false;

  /**
   * Boolean indicating whether the modal should be opened
   */
  /* eslint-disable-next-line @angular-eslint/no-input-rename */
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
        window.addEventListener('resize', this.appHeightListener);
        window.addEventListener('orientationchange', this.appHeightListener);
        this.appHeightListener();

        const focusCatcherContainer = document.querySelectorAll("[data-modal-focus-catcher-container='true']")[0];
        if (focusCatcherContainer) {
          (findAllFocusableElementsWithin(focusCatcherContainer as HTMLElement)[0] as HTMLElement).focus();
        } else {
          // Index 1 because the element at index 0 is the trigger button to open the modal
          (findAllFocusableElementsWithin(this.elementRef.nativeElement)[1] as HTMLElement).focus();
        }
      });
    } else {
      document.body.removeEventListener('click', this.closeEventListener);
      document.body.removeEventListener('keydown', this.escapeListener);
      window.removeEventListener('resize', this.appHeightListener);
      window.removeEventListener('orientationchange', this.appHeightListener);

      this.closed.emit();
    }
  }

  get open():boolean {
    return this._open;
  }

  /**
   * Emits when the drop modal closes. This is needed because you are usually controlling the opened
   * state of the modal manually because you have to define the trigger that opens the modal, but can
   * will close itself automatically if the user interacts outside of it or presses Escape.
   *
   * ```
   * <spot-drop-modal
   *   [open]="isDropModalOpen"
   *   (closed)="isDropModalOpen = false"
   * >
   *   <button
   *     slot="trigger"
   *     type="button"
   *     (click)="isDropModalOpen = true"
   *   >Open drop modal</button>
   * </spot-drop-modal>
   * ```
   */
  @Output() closed = new EventEmitter<void>();

  public text = {
    close: this.i18n.t('js.spot.drop_modal.close'),
  };

  constructor(
    readonly i18n:I18nService,
    readonly elementRef:ElementRef,
  ) {}

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
    document.body.removeEventListener('keydown', this.escapeListener);
    window.removeEventListener('resize', this.appHeightListener);
    window.removeEventListener('orientationchange', this.appHeightListener);
  }

  private closeEventListener = this.close.bind(this) as () => void;

  private onEscape = (evt:KeyboardEvent) => {
    if (evt.keyCode === KeyCodes.ESCAPE) {
      this.close();
    }
  };

  private escapeListener = this.onEscape.bind(this) as () => void;

  private appHeightListener = () => {
    const doc = document.documentElement;
    doc.style.setProperty('--app-height', `${window.innerHeight}px`);
  };
}
