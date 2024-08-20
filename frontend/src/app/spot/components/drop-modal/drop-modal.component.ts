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
import { SpotDropModalTeleportationService } from './drop-modal-teleportation.service';
import { filter, take } from 'rxjs/operators';
import { debounce } from 'lodash';
import { autoUpdate, computePosition, flip, limitShift, Placement, shift } from '@floating-ui/dom';

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

  @Input() public notFullscreen = false;

  /**
   * The default alignment of the drop modal. There are twelve alignments in total. You can check which ones they are in
   * @floating-ui/utils: `Placement` in floating-ui.utils.d.ts
   */
  @Input() public alignment:Placement = 'bottom-start';

  public _opened = false;

  /**
   * Boolean indicating whether the modal should be opened
   */
  /* eslint-disable-next-line @angular-eslint/no-input-rename */
  @Input('opened')
  @HostBinding('class.spot-drop-modal_opened')
  set opened(value:boolean) {
    if (this._opened === value) {
      return;
    }

    if (value) {
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

  public id = `drop-modal-${Math.round(Math.random() * 10000)}`;

  public text = {
    close: this.i18n.t('js.spot.drop_modal.close'),
    focus_grab: this.i18n.t('js.spot.drop_modal.focus_grab'),
  };

  private cleanupFloatingUI:() => void|undefined;

  @ViewChild('anchor') anchor:ElementRef;

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
    this.updateAppHeight();
    this.cdRef.detectChanges();

    /*
     * If we don't activate the body after one tick, angular will complain because
     * it already rendered a `null` template, but then gets an update to that
     * template in the same tick.
     * To make it happy, we update afterwards
     */
    this.teleportationService.activate(this.body);

    this.teleportationService
      .hasRenderedFiltered$
      .pipe(
        filter((hasRendered) => !!hasRendered),
        take(1),
      )
      .subscribe(() => {
        const referenceEl = this.elementRef.nativeElement as HTMLElement;
        const floatingEl = this.anchor.nativeElement as HTMLElement;
        this.cleanupFloatingUI = autoUpdate(
          referenceEl,
          floatingEl,
          /* eslint-disable-next-line @typescript-eslint/no-misused-promises */
          async () => {
            const { x, y } = await computePosition(
              referenceEl,
              floatingEl,
              {
                placement: this.alignment,
                middleware: this.allowRepositioning ? [
                  flip({
                    mainAxis: true,
                    crossAxis: true,
                    fallbackAxisSideDirection: 'start',
                  }),
                  shift({ limiter: limitShift() }),
                ] : [],
              },
            );

            Object.assign(floatingEl.style, {
              left: `${x}px`,
              top: `${y}px`,
            });
          },
        );
        /*
         * We have to set these listeners next tick, because they're so far up the tree.
         * If the open value was set because of a click listener in the trigger slot,
         * that event would reach the event listener added here and close the modal right away.
         */
        setTimeout(() => {
          document.body.addEventListener('click', this.onGlobalClick);
          document.body.addEventListener('keydown', this.onEscape);
          window.addEventListener('resize', this.onResize);
          window.addEventListener('orientationchange', this.onResize);

          const focusCatcherContainer = document.querySelectorAll("[data-modal-focus-catcher-container='true']")[0];
          if (focusCatcherContainer) {
            (findAllFocusableElementsWithin(focusCatcherContainer as HTMLElement)[0])?.focus();
          } else {
            // Index 1 because the element at index 0 is the trigger button to open the modal
            (findAllFocusableElementsWithin(document.querySelector('.spot-drop-modal-portal')!)[1])?.focus();
          }

          this.cdRef.detectChanges();
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
    window.removeEventListener('resize', this.onResize);
    window.removeEventListener('orientationchange', this.onResize);

    this.teleportationService.clear();
    this.cdRef.detectChanges();
    (this.focusGrabber.nativeElement as HTMLElement).focus();
  }

  private onGlobalClick = this.close.bind(this) as () => void;

  ngOnDestroy():void {
    if (this.opened) {
      this.teleportationService.clear();
    }

    document.body.removeEventListener('click', this.onGlobalClick);
    document.body.removeEventListener('keydown', this.onEscape);
    window.removeEventListener('resize', this.onResize);
    window.removeEventListener('orientationchange', this.onResize);
    this.cleanupFloatingUI?.();
  }

  onBodyClick(e:MouseEvent):void {
    // We stop propagation here so that clicks inside the body do not
    // close the modal when the event reaches the document body
    e.stopPropagation();
  }

  private escapeCallback = (evt:KeyboardEvent) => {
    if (evt.keyCode === KeyCodes.ESCAPE) {
      this.close();
    }
  };

  private onEscape = debounce(this.escapeCallback.bind(this), 10);

  private resizeCallback():void {
    this.updateAppHeight();
  }

  private onResize = debounce(this.resizeCallback.bind(this), 10);

  private updateAppHeight = () => {
    const doc = document.documentElement;
    doc.style.setProperty('--app-height', `${window.innerHeight}px`);
  };
}
