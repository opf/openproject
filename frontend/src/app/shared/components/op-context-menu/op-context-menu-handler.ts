import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

/**
 * Interface passed to CM service to open a particular context menu.
 * This will often be a trigger component, but does not have to be.
 */
export abstract class OpContextMenuHandler extends UntilDestroyedMixin {
  protected $element:JQuery;

  protected items:OpContextMenuItem[] = [];

  constructor(readonly opContextMenu:OPContextMenuService) {
    super();
  }

  /**
   * Called when the service closes this context menu
   *
   * @param focus Focus on the trigger again
   */
  public onClose(focus = false) {
    if (focus) {
      this.afterFocusOn.trigger('focus');
    }
  }

  public onOpen(menu:JQuery) {
    menu.find('.menu-item').first().trigger('focus');
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(openerEvent:JQuery.TriggeredEvent|Event):JQueryUI.JQueryPositionOptions {
    return {
      my: 'left top',
      at: 'right bottom',
      of: openerEvent,
      collision: 'flipfit',
    };
  }

  /**
   * Get the locals passed to the op-context-menu component
   */
  public get locals():{ showAnchorRight?:boolean, contextMenuId?:string, items:OpContextMenuItem[] } {
    return {
      items: this.items,
    };
  }

  /**
   * Open this context menu
   */
  protected open(evt:JQuery.TriggeredEvent):void {
    this.opContextMenu.show(this, evt);
  }

  protected get afterFocusOn():JQuery {
    return this.$element;
  }
}
