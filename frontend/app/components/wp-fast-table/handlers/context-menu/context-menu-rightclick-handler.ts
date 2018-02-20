import {Injector} from '@angular/core';
import {debugLog} from '../../../../helpers/debug_output';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {timelineCellClassName} from '../../builders/timeline/timeline-row-builder';
import {uiStateLinkClass} from '../../builders/ui-state-link-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {ContextMenuHandler} from './context-menu-handler';

export class ContextMenuRightClickHandler extends ContextMenuHandler {

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {

    super(injector, table);
  }

  public get EVENT() {
    return 'contextmenu.table.rightclick';
  }

  public get SELECTOR() {
    return `.${tableRowClassName},.${timelineCellClassName}`;
  }

  public handleEvent(table:WorkPackageTable, evt:JQueryEventObject):boolean {
    let target = jQuery(evt.target);

    // We want to keep the original context menu on hrefs
    // (currently, this is only the id
    if (target.closest(`.${uiStateLinkClass}`).length) {
      debugLog('Allowing original context menu on state link');
      return true;
    }

    evt.preventDefault();
    evt.stopPropagation();

    // Locate the row from event
    const element = target.closest(this.SELECTOR);
    const wpId = element.data('workPackageId');

    if (wpId) {
      super.openContextMenu(evt, wpId);
    }

    return false;
  }
}
