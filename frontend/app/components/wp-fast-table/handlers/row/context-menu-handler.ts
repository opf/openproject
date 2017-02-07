import {debug_log} from '../../../../helpers/debug_output';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {rowClassName} from '../../builders/rows/single-row-builder';
import {tdClassName} from '../../builders/cell-builder';
import {uiStateLinkClass} from '../../builders/ui-state-link-builder';
import {ContextMenuService} from '../../../context-menus/context-menu.service';

export class ContextMenuHandler implements TableEventHandler {
  // Injections
  public contextMenu:ContextMenuService;

  constructor() {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'contextmenu.table.rightclick';
  }

  public get SELECTOR() {
    return `.${rowClassName}`;
  }

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    let target = jQuery(evt.target);

    // We want to keep the original context menu on hrefs
    // (currently, this is only the id
    if (target.closest(`.${uiStateLinkClass}`).length) {
      debug_log('Allowing original context menu on state link');
      return;
    }
    evt.preventDefault();
    evt.stopPropagation();

    // Locate the row from event
    let element = target.closest(this.SELECTOR);
    let row = table.rowObject(element.data('workPackageId'));

    this.contextMenu.activate('WorkPackageContextMenu', evt, { row: row });
    return false;
  }
}

ContextMenuHandler.$inject = ['contextMenu'];
