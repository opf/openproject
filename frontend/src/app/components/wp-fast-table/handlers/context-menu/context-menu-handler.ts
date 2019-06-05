import {Injector} from '@angular/core';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventHandler} from '../table-handler-registry';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {OpWorkPackageContextMenu} from "core-components/op-context-menu/wp-context-menu/wp-table-context-menu.directive";

export abstract class ContextMenuHandler implements TableEventHandler {
  // Injections
  public opContextMenu:OPContextMenuService = this.injector.get(OPContextMenuService);

  constructor(public readonly injector:Injector,
              protected table:WorkPackageTable) {
  }

  public get rowSelector() {
    return `.${tableRowClassName}`;
  }

  public abstract get EVENT():string;

  public abstract get SELECTOR():string;

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.container);
  }

  public abstract handleEvent(table:WorkPackageTable, evt:JQueryEventObject):boolean;

  protected openContextMenu(evt:JQueryEventObject, workPackageId:string, positionArgs?:any):void {
    const handler = new OpWorkPackageContextMenu(this.injector, this.table, workPackageId, jQuery(evt.target) as JQuery, positionArgs);
    this.opContextMenu.show(handler, evt);
  }
}
