import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {OpContextMenuItem} from 'core-components/op-context-menu/op-context-menu.types';

/**
 * Interface passed to CM service to open a particular context menu.
 * This will often be a trigger component, but does not have to be.
 */
export abstract class OpContextMenuHandler {
  protected $element:JQuery;
  protected items:OpContextMenuItem[] = [];

  constructor(readonly opContextMenu:OPContextMenuService) {
  }

  /**
   * Called when the service closes this context menu
   */
  public onClose() {
    this.afterFocusOn.focus();
  }

  public onOpen(menu:JQuery) {
    menu.find('.menu-item').first().focus();
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(openerEvent:JQueryEventObject):any {
    return {
      my: 'left top',
      at: 'right bottom',
      of: openerEvent,
      collision: 'flipfit'
    };
  }

  /**
   * Get the locals passed to the op-context-menu component
   */
  public get locals():{ showAnchorRight?:boolean, contextMenuId?:string, items:OpContextMenuItem[] } {
    return {
      items: this.items
    };
  }

  /**
   * Open this context menu
   */
  protected open(evt:JQueryEventObject) {
    this.opContextMenu.show(this, evt);
  }

  protected get afterFocusOn():JQuery {
    return this.$element;
  }
}
