import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageTable} from "../../wp-fast-table";
import {TableEventHandler} from "../table-handler-registry";
import {tableRowClassName} from "../../builders/rows/single-row-builder";
import {ContextMenuService} from "../../../context-menus/context-menu.service";
import {keyCodes} from "../../../common/keyCodes.enum";

export class ContextMenuKeyboardHandler implements TableEventHandler {
  // Injections
  public contextMenu:ContextMenuService;

  constructor(table: WorkPackageTable) {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'keydown.table.contextmenu';
  }

  public get SELECTOR() {
    return `.${tableRowClassName}`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.tbody);
  }

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject):boolean {
    let target = jQuery(evt.target);

    if (!(evt.keyCode === keyCodes.F10 && evt.shiftKey && evt.altKey)) {
      return true;
    }

    evt.preventDefault();
    evt.stopPropagation();

    // Locate the row from event
    let element = target.closest(this.SELECTOR);
    let row = table.rowObject(element.data('workPackageId'));

    // Set position args to open at element
    let position = { of: target };

    this.contextMenu.activate('WorkPackageContextMenu', evt, { row: row }, position);
    return false;
  }
}

ContextMenuKeyboardHandler.$inject = ['contextMenu'];
