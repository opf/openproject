import { Injector } from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { contextMenuLinkClassName } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { TableEventComponent } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { uiStateLinkClass } from '../../builders/ui-state-link-builder';
import { ContextMenuHandler } from './context-menu-handler';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class ContextMenuClickHandler extends ContextMenuHandler {
  constructor(public readonly injector:Injector) {
    super(injector);
  }

  public get EVENT():EventType {
    return 'click';
  }

  public get SELECTOR() {
    return `.${contextMenuLinkClassName}`;
  }

  public handleEvent(view:TableEventComponent, evt:Event):boolean {
    const target = evt.target as HTMLElement;

    // We want to keep the original context menu on hrefs
    // (currently, this is only the id
    if (target.closest(`.${uiStateLinkClass}`)) {
      debugLog('Allowing original context menu on state link');
      return true;
    }

    evt.preventDefault();
    evt.stopPropagation();

    // Locate the row from event
    const element = target.closest<HTMLTableRowElement>(this.rowSelector);
    const wpId = element?.dataset.workPackageId;

    if (wpId) {
      this.openContextMenu(view.workPackageTable, evt, wpId);
    }

    return false;
  }
}
