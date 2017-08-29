import {debugLog} from "../../../../helpers/debug_output";
import {$injectFields, injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageTable} from "../../wp-fast-table";
import {TableEventHandler} from "../table-handler-registry";
import {tableRowClassName} from "../../builders/rows/single-row-builder";
import {uiStateLinkClass} from "../../builders/ui-state-link-builder";
import {ContextMenuService} from "../../../context-menus/context-menu.service";
import {timelineCellClassName} from "../../builders/timeline/timeline-row-builder";

export abstract class ContextMenuHandler implements TableEventHandler {
  // Injections
  public contextMenu:ContextMenuService;

  constructor(protected table: WorkPackageTable) {
    $injectFields(this, 'contextMenu');
  }

  public get rowSelector() {
    return `.${tableRowClassName}`;
  }

  public abstract get EVENT():string;

  public abstract get SELECTOR():string;

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.container);
  }

  public abstract handleEvent(table: WorkPackageTable, evt:JQueryEventObject):boolean;

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
