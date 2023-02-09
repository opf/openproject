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
  TemplateRef,
  ViewChild,
} from '@angular/core';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { findAllFocusableElementsWithin } from 'core-app/shared/helpers/focus-helpers';
import SpotDropAlignmentOption from '../../drop-alignment-options';
import { SpotDropModalTeleportationService } from './drop-modal-teleportation.service';
import { filter, take } from 'rxjs/operators';
import { debounce } from 'lodash';

const findClippingParent = (el:HTMLElement):HTMLElement => {
  const parent = el.parentElement;
  if (!parent) {
    return document.body;
  }

  const styles = window.getComputedStyle(parent);
  if (styles.overflowY !== 'visible' || styles.overflowX !== 'visible') {
    return parent;
  }

  return findClippingParent(parent);
};

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
  @Input() public allowRepositioning = true;

  /**
   * The default alignment of the drop modal. There are twelve alignments in total. You can check which ones they are
   * from the `SpotDropAlignmentOption` Enum that is available in 'core-app/spot/drop-alignment-options'.
   */
  @Input() public alignment:SpotDropAlignmentOption = SpotDropAlignmentOption.BottomLeft;

  private calculatedAlignment = SpotDropAlignmentOption.BottomLeft;

  get alignmentClass():string {
    return `spot-drop-modal--body_${this.allowRepositioning ? this.calculatedAlignment : this.alignment}`;
  }

  public _opened = false;

  /**
   * Boolean indicating whether the modal should be opened
   */
  /* eslint-disable-next-line @angular-eslint/no-input-rename */
  @Input('opened')
  @HostBinding('class.spot-drop-modal_opened')
  set opened(value:boolean) {
    if (this._opened === !!value) {
      return;
    }

    if (!!value) {
      this.open();
    } else {
      this.close();
    }
  }

  get opened():boolean {
    return this._opened;
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

  public anchorStyles = {
    top: '0',
    left: '0',
    width: '0',
    height: '0',
  };

  public id = `drop-modal-${Math.round(Math.random() * 10000)}`;

  public text = {
    close: this.i18n.t('js.spot.drop_modal.close'),
    focus_grab: this.i18n.t('js.spot.drop_modal.focus_grab'),
  };

  @ViewChild('body') body:TemplateRef<any>;

  @ViewChild('focusGrabber') focusGrabber:ElementRef;

  constructor(
    readonly i18n:I18nService,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    private teleportationService:SpotDropModalTeleportationService,
  ) {}

  open() {
    this._opened = true;
    this.repositionAnchor();
    this.updateAppHeight();
    this.cdRef.detectChanges();

    /*
     * If we don't activate the body after one tick, angular will complain because
     * it already rendered a `null` template, but then gets an update to that
     * template in the same tick.
     * To make it happy, we update afterwards
     */
    this.teleportationService.activate(this.body)

    this.teleportationService
      .hasRenderedFiltered$
      .pipe(
        filter((hasRendered) => hasRendered),
        take(1),
      )
      .subscribe(() => {
        /*
         * We have to set these listeners next tick, because they're so far up the tree.
         * If the open value was set because of a click listener in the trigger slot,
         * that event would reach the event listener added here and close the modal right away.
         */
        setTimeout(() => {
          document.body.addEventListener('click', this.onGlobalClick);
          document.body.addEventListener('keydown', this.onEscape);
          document.body.addEventListener('scroll', this.onScroll, true);
          window.addEventListener('resize', this.onResize);
          window.addEventListener('orientationchange', this.onResize);

          this.recalculateAlignment();

          const focusCatcherContainer = document.querySelectorAll("[data-modal-focus-catcher-container='true']")[0];
          if (focusCatcherContainer) {
            (findAllFocusableElementsWithin(focusCatcherContainer as HTMLElement)[0] as HTMLElement)?.focus();
          } else {
            // Index 1 because the element at index 0 is the trigger button to open the modal
            (findAllFocusableElementsWithin(document.querySelector('.spot-drop-modal-portal')!)[1] as HTMLElement)?.focus();
          }
        });
      });
  }

  close():void {
    this._opened = false;
    this.closed.emit();

    /*
     * The same as with opening; if we don't deactivate the body after
     * one tick, angular will complain because it already rendered the
     * template, but then gets an update to render `null` in the same tick.
     *
     * To make it happy, we update afterwards
     */
    document.body.removeEventListener('click', this.onGlobalClick);
    document.body.removeEventListener('keydown', this.onEscape);
    document.body.removeEventListener('scroll', this.onScroll);
    window.removeEventListener('resize', this.onResize);
    window.removeEventListener('orientationchange', this.onResize);

    this.teleportationService.clear();
    this.cdRef.detectChanges();
    this.focusGrabber.nativeElement.focus();
  }

  private onGlobalClick = this.close.bind(this);

  ngOnDestroy():void {
    this.teleportationService.clear();
    document.body.removeEventListener('click', this.onGlobalClick);
    document.body.removeEventListener('keydown', this.onEscape);
    document.body.removeEventListener('scroll', this.onScroll);
    window.removeEventListener('resize', this.onResize);
    window.removeEventListener('orientationchange', this.onResize);
  }

  onBodyClick(e:MouseEvent):void {
    // We stop propagation here so that clicks inside the body do not
    // close the modal when the event reaches the document body
    e.stopPropagation();
  }

  private recalculateAlignment(): void {
    const anchor = document.getElementById(this.id);
    if (!anchor) { return; }

    const modalBody = anchor.querySelector('.spot-drop-modal--body');
    if (!modalBody) { return; }

    const alignments = Object.values(SpotDropAlignmentOption) as SpotDropAlignmentOption[];
    const index = alignments.indexOf(this.alignment);
    const originalAlignmentClass = this.alignmentClass;

    const possibleAlignment = [
      ...alignments.splice(index),
      ...alignments.splice(0, index),
    ].find((alignment:SpotDropAlignmentOption) => {
        modalBody.classList.remove(this.alignmentClass);
        this.calculatedAlignment = alignment; 
        modalBody.classList.add(this.alignmentClass);
        const rect = modalBody.getBoundingClientRect();

        const spaceOnLeft = rect.left >= 0;
        const spaceOnRight = rect.right <= window.innerWidth;
        const spaceOnTop = rect.top >= 0;
        const spaceOnBottom = rect.bottom <= window.innerHeight;
        return spaceOnLeft && spaceOnRight && spaceOnTop && spaceOnBottom;
      });

    /**
     * We need to remove any residual classes left on the nativeElement after
     * calculating the possibleAlignments. The final calculated alignment
     * is applied via the `alignmentClass` function anyway.
     */
    modalBody.classList.remove(this.alignmentClass);
    modalBody.classList.add(originalAlignmentClass);

    if (possibleAlignment) {
      this.calculatedAlignment = possibleAlignment;
    } else {
      this.calculatedAlignment = this.alignment;
    }

    this.cdRef.detectChanges();
  }

  private escapeCallback = (evt:KeyboardEvent) => {
    if (evt.keyCode === KeyCodes.ESCAPE) {
      this.close();
    }
  };

  private onEscape = debounce(this.escapeCallback.bind(this), 10);

  private resizeCallback():void {
    this.updateAppHeight();
    this.repositionAnchor();
    this.recalculateAlignment();
  }

  private onResize = debounce(this.resizeCallback.bind(this), 10);

  private updateAppHeight = () => {
    const doc = document.documentElement;
    doc.style.setProperty('--app-height', `${window.innerHeight}px`);
  };

  private repositionAnchor():void {
    const elementRect = (this.elementRef.nativeElement as HTMLElement).getBoundingClientRect();
    this.anchorStyles.top = `${elementRect.top}px`;
    this.anchorStyles.left = `${elementRect.left}px`;
    this.anchorStyles.width = `${elementRect.width}px`;
    this.anchorStyles.height = `${elementRect.height}px`;
  }

  private onScroll = debounce(this.repositionAnchor.bind(this), 16);
}
