import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {rowClassName} from '../../builders/rows/single-row-builder';
import {cellClassName} from '../../builders/cell-builder';
import {tdClassName} from '../../builders/cell-builder';
import {uiStateLinkClass} from '../../builders/ui-state-link-builder';
import {ContextMenuService} from '../../../context-menus/context-menu.service';
import {keyCodes} from '../../../common/keyCodes.enum';

export class ContextMenuKeyboardHandler implements TableEventHandler {
  // Injections
  public contextMenu:ContextMenuService;

  constructor() {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'keydown.table.contextmenu';
  }

  public get SELECTOR() {
    return `.${rowClassName}`;
  }

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    let target = jQuery(evt.target);

    if (!(evt.keyCode === keyCodes.F10 && evt.shiftKey && evt.altKey)) {
      return;
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
