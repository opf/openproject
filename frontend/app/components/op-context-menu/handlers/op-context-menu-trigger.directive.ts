import {AfterViewInit, Directive, ElementRef, Input} from "@angular/core";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {OpContextMenuHandler} from "core-components/op-context-menu/op-context-menu-handler";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";

@Directive({
  selector: '[opContextMenuTrigger]'
})
export class OpContextMenuTrigger extends OpContextMenuHandler implements AfterViewInit {
  // Where to focus after this menu closes
  @Input('afterFocusOn') public afterFocusOn:string;

  protected $element:JQuery;
  protected items:OpContextMenuItem[] = [];

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService) {
    super(opContextMenu);
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
}
