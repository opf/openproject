import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  HostBinding,
  Input,
  OnDestroy,
  Output,
  ViewChild,
} from '@angular/core';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { findAllFocusableElementsWithin } from 'core-app/shared/helpers/focus-helpers';
import SpotDropAlignmentOption from '../../drop-alignment-options';

const findClippingParent = (el:HTMLElement):HTMLElement => {
  const parent = el.parentElement;
  if(!parent) {
    return document.body;
  }

  const styles = window.getComputedStyle(parent);
  if (styles.overflowY !== 'visible' || styles.overflowX !== 'visible') {
    return parent;
  }

  return findClippingParent(parent);
}

@Component({
  selector: 'spot-drop-modal',
  templateUrl: './drop-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SpotDropModalComponent implements OnDestroy {
  @HostBinding('class.spot-drop-modal') public className = true;

  /**
   * Whether to allow automatic changing the alignment based on the available space.
   */
  @Input() public allowRepositioning:boolean = true;

  /**
   * The default alignment of the drop modal. There are twelve alignments in total. You can check which ones they are
   * from the `SpotDropAlignmentOption` Enum that is available in 'core-app/spot/drop-alignment-options'.
   */
  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomLeft;

  private calculatedAlignment = SpotDropAlignmentOption.BottomLeft;

  get alignmentClass():string {
    return `spot-drop-modal--body_${this.allowRepositioning ? this.calculatedAlignment : this.alignment}`;
  }

  public _open = false;

  /**
   * Boolean indicating whether the modal should be opened
   */
  /* eslint-disable-next-line @angular-eslint/no-input-rename */
  @Input('open')
  @HostBinding('class.spot-drop-modal_opened')
  set open(value:boolean) {
    if (this._open === !!value) {
      return;
    }

    this._open = !!value;

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

        if (this.allowRepositioning) {
          this.recalculateAlignment();
        }

        // If we already have focus within the modal, don't move it
        if (this.elementRef.nativeElement.contains(document.activeElement)) {
          return;
        }

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

  @ViewChild('modalBody') modalBody:ElementRef;

  constructor(
    readonly i18n:I18nService,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
  ) {}

  close():void {
    this.open = false;
  }

  private closeEventListener = this.close.bind(this) as () => void;

  onBodyClick(e:MouseEvent):void {
    // We stop propagation here so that clicks inside the body do not
    // close the modal when the event reaches the document body
    e.stopPropagation();
  }

  private recalculateAlignment(): void {
    const clippingParent = findClippingParent(this.elementRef.nativeElement);
    const parentRect = clippingParent.getBoundingClientRect();

    const alignments = Object.values(SpotDropAlignmentOption) as SpotDropAlignmentOption[];
    const index = alignments.indexOf(this.alignment);

    const possibleAlignments = [
      ...alignments.splice(index),
      ...alignments.splice(0, index),
    ].filter((alignment:SpotDropAlignmentOption) => {
        this.modalBody.nativeElement.classList.remove(this.alignmentClass);
        this.calculatedAlignment = alignment; 
        this.modalBody.nativeElement.classList.add(this.alignmentClass);
        const rect = this.modalBody.nativeElement.getBoundingClientRect();

        const spaceOnLeft = parentRect.left <= rect.left;
        const spaceOnRight = parentRect.right >= rect.right;
        const spaceOnTop = parentRect.top <= rect.top;
        const spaceOnBottom = parentRect.bottom >= rect.bottom;
        return spaceOnLeft && spaceOnRight && spaceOnTop && spaceOnBottom;
      });

    if (possibleAlignments.length) {
      this.calculatedAlignment = possibleAlignments[0];
    } else {
      this.calculatedAlignment = this.alignment;
    }

    this.cdRef.markForCheck();
  }

  ngOnDestroy():void {
    document.body.removeEventListener('click', this.closeEventListener);
    document.body.removeEventListener('keydown', this.escapeListener);
    window.removeEventListener('resize', this.appHeightListener);
    window.removeEventListener('orientationchange', this.appHeightListener);
  }

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
