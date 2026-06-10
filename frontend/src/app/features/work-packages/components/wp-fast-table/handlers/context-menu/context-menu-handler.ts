import { Injector } from '@angular/core';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageTableContextMenu } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-table-context-menu.directive';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { PositionArgs } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-view-context-menu.directive';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export abstract class ContextMenuHandler implements TableEventHandler {
  // Injections
  @LazyInject() public opContextMenu:OPContextMenuService;

  constructor(public readonly injector:Injector) {
  }

  public get rowSelector() {
    return `.${tableRowClassName}`;
  }

  public abstract get EVENT():EventType|EventType[];

  public abstract get SELECTOR():string;

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tableAndTimelineContainer;
  }

  public abstract handleEvent(view:TableEventComponent, evt:Event):boolean;

  protected openContextMenu(table:WorkPackageTable, evt:Event, workPackageId:string, positionArgs:PositionArgs = {}):void {
    const handler = new WorkPackageTableContextMenu(this.injector, workPackageId, evt.target as HTMLElement, positionArgs, table);
    this.opContextMenu.show(handler, evt);
  }
}
