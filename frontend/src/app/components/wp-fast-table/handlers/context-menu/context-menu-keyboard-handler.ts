import {Injector} from '@angular/core';
import {keyCodes} from 'core-app/modules/common/keyCodes.enum';
import {WorkPackageTable} from '../../wp-fast-table';
import {ContextMenuHandler} from './context-menu-handler';

export class ContextMenuKeyboardHandler extends ContextMenuHandler {

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
    super(injector, table);
  }

  public get EVENT() {
    return 'keydown.table.contextmenu';
  }

  public get SELECTOR() {
    return this.rowSelector;
  }

  public handleEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):boolean {
    if (!table.configuration.contextMenuEnabled) {
      return false;
    }

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
    let position = { my: 'left top', at: 'left bottom', of: target };

    super.openContextMenu(evt, wpId, position);

    return false;
  }
}
