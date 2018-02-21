import {Injector} from '@angular/core';
import {ContextMenuService} from '../../../context-menus/context-menu.service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventHandler} from '../table-handler-registry';

export abstract class ContextMenuHandler implements TableEventHandler {
  // Injections
  public contextMenu:ContextMenuService = this.injector.get(ContextMenuService);

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
    let [index,] = this.table.findRenderedRow(workPackageId);
    this.contextMenu.activate(
      'WorkPackageContextMenu',
      evt,
      {
        workPackageId: workPackageId,
        rowIndex: index,
        table: this.table
      }
    );
  }
}
