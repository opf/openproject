import {AfterViewInit, Directive, ElementRef, Injector, Input} from "@angular/core";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.component";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";

@Directive({
  selector: '[opContextMenuTrigger]'
})
export abstract class OpContextMenuTrigger implements AfterViewInit {
  // Where to focus after this menu closes
  @Input('afterFocusOn') public afterFocusOn:string;

  protected $element:JQuery;
  protected items:OpContextMenuItem[] = [];

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService) {
  }

  ngAfterViewInit():void {
    this.$element = jQuery(this.elementRef.nativeElement);

    // Open by clicking the element
    this.$element.click((evt) => {
      evt.preventDefault();
      evt.stopPropagation();

      // When clicking the same trigger twice, close the element instead.
      if (this.opContextMenu.isActive(this)) {
        this.opContextMenu.close();
        return false;
      }

      this.open(evt);
      return false;
    });

    // Open with keyboard combination as well
    Mousetrap(this.$element[0]).bind('shift+alt+f10', (evt) => {
      this.open(evt);
    });
  }

  /**
   * Called when the service closes this context menu
   */
  public onClose() {
    let target =  this.$element;
    if (this.afterFocusOn) {
      target = this.$element.find(this.afterFocusOn);
    }

    target.focus();
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(openerEvent:Event):any {
    return {
      my: 'left top',
      at: 'right bottom',
      of: openerEvent
    };
  }

  /**
   * Get the locals passed to the op-context-menu component
   */
  public get locals() {
    return {
      items: this.items
    };
  }

  /**
   * Open this context menu
   * @param {Event} evt
   */
  protected open(evt:Event) {
    this.opContextMenu.show(this, evt);
  }
}
