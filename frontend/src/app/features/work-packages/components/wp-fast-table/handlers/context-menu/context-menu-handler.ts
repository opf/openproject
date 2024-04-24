import { Injector } from '@angular/core';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageTableContextMenu } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-table-context-menu.directive';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';

export abstract class ContextMenuHandler implements TableEventHandler {
  // Injections
  @InjectField() public opContextMenu:OPContextMenuService;

  constructor(public readonly injector:Injector) {
  }

  public get rowSelector() {
    return `.${tableRowClassName}`;
  }

  public abstract get EVENT():string;

  public abstract get SELECTOR():string;

  public eventScope(view:TableEventComponent) {
    return jQuery(view.workPackageTable.tableAndTimelineContainer);
  }

  public abstract handleEvent(view:TableEventComponent, evt:JQuery.TriggeredEvent):boolean;

  protected openContextMenu(table:WorkPackageTable, evt:JQuery.TriggeredEvent, workPackageId:string, positionArgs?:any):void {
    const handler = new WorkPackageTableContextMenu(this.injector, workPackageId, jQuery(evt.target) as JQuery, positionArgs, table);
    this.opContextMenu.show(handler, evt);
  }
}
