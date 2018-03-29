import {AfterViewInit, Directive, ElementRef} from "@angular/core";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {OpContextMenuHandler} from "core-components/op-context-menu/op-context-menu-handler";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";

@Directive({
  selector: '[opContextMenuTrigger]'
})
export class OpContextMenuTrigger implements OpContextMenuHandler, AfterViewInit {
  protected $element:JQuery;
  protected items:OpContextMenuItem[] = [];

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService) {
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
   */
  public open(evt:Event) {
    this.opContextMenu.show(this, evt);
  }

  public onOpen(menu:JQuery) {
    menu.find('.menu-item').first().focus();
  }

  public onClose() {
    this.afterFocusOn.focus();
  }

  public get afterFocusOn():JQuery {
    return this.$element;
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
}
