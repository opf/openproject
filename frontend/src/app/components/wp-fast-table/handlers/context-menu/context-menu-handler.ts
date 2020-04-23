import {Injector} from '@angular/core';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventHandler} from '../table-handler-registry';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {WorkPackageTableContextMenu} from "core-components/op-context-menu/wp-context-menu/wp-table-context-menu.directive";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export abstract class ContextMenuHandler implements TableEventHandler {
  // Injections
  @InjectField() public opContextMenu:OPContextMenuService;

  constructor(public readonly injector:Injector,
              protected table:WorkPackageTable) {
  }

  public get rowSelector() {
    return `.${tableRowClassName}`;
  }

  public abstract get EVENT():string;

  public abstract get SELECTOR():string;

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.tableAndTimelineContainer);
  }

  public abstract handleEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):boolean;

  protected openContextMenu(evt:JQuery.TriggeredEvent, workPackageId:string, positionArgs?:any):void {
    const handler = new WorkPackageTableContextMenu(this.injector, workPackageId, jQuery(evt.target) as JQuery, positionArgs, this.table);
    this.opContextMenu.show(handler, evt);
  }
}
