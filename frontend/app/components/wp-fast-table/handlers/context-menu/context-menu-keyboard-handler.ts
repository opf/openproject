import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageTable} from "../../wp-fast-table";
import {tableRowClassName} from "../../builders/rows/single-row-builder";
import {ContextMenuService} from "../../../context-menus/context-menu.service";
import {keyCodes} from "../../../common/keyCodes.enum";
import {ContextMenuHandler} from "./context-menu-handler";

export class ContextMenuKeyboardHandler extends ContextMenuHandler {
  constructor(table:WorkPackageTable) {
    super(table);
  }

  public get EVENT() {
    return 'keydown.table.contextmenu';
  }

  public get SELECTOR() {
    return this.rowSelector;
  }

  public handleEvent(table:WorkPackageTable, evt:JQueryEventObject):boolean {
    let target = jQuery(evt.target);

    if (!(evt.keyCode === keyCodes.F10 && evt.shiftKey && evt.altKey)) {
      return true;
    }

    evt.preventDefault();
    evt.stopPropagation();

    // Locate the row from event
    const element = target.closest(this.SELECTOR);
    const wpId = element.data('workPackageId');

    // Set position args to open at element
    let position = { of: target };

    super.openContextMenu(evt, wpId, position);

    return false;
  }
}
