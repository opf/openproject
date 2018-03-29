import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {
  OpContextMenuItem,
  OpContextMenuLocalsMap
} from "core-components/op-context-menu/op-context-menu.types";
import {Directive} from '@angular/core';

/**
 * Interface passed to CM service to open a particular context menu.
 * This will often be a trigger component, but does not have to be.
 */
export interface OpContextMenuHandler {

  /**
   * Called when the service closes this context menu
   */
  onClose():void;
  onOpen(menu:JQuery):void;
  positionArgs(openerEvent:Event):any;
  open(evt:Event):void;

  locals:OpContextMenuLocalsMap;
}
