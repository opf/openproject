import {Injector} from '@angular/core';
import {debugLog} from '../../../../helpers/debug_output';
import {uiStateLinkClass} from '../../builders/ui-state-link-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {ContextMenuHandler} from './context-menu-handler';
import {contextMenuLinkClassName} from "core-components/wp-table/table-actions/table-action";

export class ContextMenuClickHandler extends ContextMenuHandler {

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
    super(injector, table);
  }

  public get EVENT() {
    return 'click.table.contextmenu';
  }

  public get SELECTOR() {
    return `.${contextMenuLinkClassName}`;
  }

  public handleEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):boolean {
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
    const element = target.closest(this.rowSelector);
    const wpId = element.data('workPackageId');

    if (wpId) {
      super.openContextMenu(evt, wpId);
    }

    return false;
  }
}
