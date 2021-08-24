import { Injector } from '@angular/core';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { TableEventComponent } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { ContextMenuHandler } from './context-menu-handler';

export class ContextMenuKeyboardHandler extends ContextMenuHandler {
  constructor(public readonly injector:Injector) {
    super(injector);
  }

  public get EVENT() {
    return 'keydown.table.contextmenu';
  }

  public get SELECTOR() {
    return this.rowSelector;
  }

  public handleEvent(component:TableEventComponent, evt:JQuery.TriggeredEvent):boolean {
    if (!component.workPackageTable.configuration.contextMenuEnabled) {
      return false;
    }

    const target = jQuery(evt.target);

    if (!(evt.keyCode === KeyCodes.F10 && evt.shiftKey && evt.altKey)) {
      return true;
    }

    evt.preventDefault();
    evt.stopPropagation();

    // Locate the row from event
    const element = target.closest(this.SELECTOR);
    const wpId = element.data('workPackageId');

    // Set position args to open at element
    const position = { my: 'left top', at: 'left bottom', of: target };

    super.openContextMenu(component.workPackageTable, evt, wpId, position);

    return false;
  }
}
