import {AfterViewInit, Directive, ElementRef} from "@angular/core";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {OpContextMenuHandler} from "core-components/op-context-menu/op-context-menu-handler";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";

@Directive({
  selector: '[opContextMenuTrigger]'
})
export class OpContextMenuTrigger extends OpContextMenuHandler implements AfterViewInit {
  protected $element:JQuery;
  protected items:OpContextMenuItem[] = [];

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService) {
    super(opContextMenu);
  }

  ngAfterViewInit():void {
    this.$element = jQuery(this.elementRef.nativeElement);

    // Open by clicking the element
    this.$element.on('click', (evt:JQuery.TriggeredEvent) => {
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
    Mousetrap(this.$element[0]).bind('shift+alt+f10', (evt:any) => {
      this.open(evt);
    });
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(openerEvent:JQuery.TriggeredEvent) {
    return {
      my: 'left top',
      at: 'left bottom',
      of: this.$element,
      collision: 'flipfit'
    };
  }
}
