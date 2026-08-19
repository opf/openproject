import { Injector } from '@angular/core';
import { TableEventComponent } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { ContextMenuHandler } from './context-menu-handler';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class ContextMenuKeyboardHandler extends ContextMenuHandler {
  constructor(public readonly injector:Injector) {
    super(injector);
  }

  public get EVENT():EventType {
    return 'keydown';
  }

  public get SELECTOR() {
    return this.rowSelector;
  }

  public handleEvent(component:TableEventComponent, evt:KeyboardEvent):boolean {
    if (!component.workPackageTable.configuration.contextMenuEnabled) {
      return false;
    }

    const target = evt.target as HTMLElement;

    if (!(evt.key === 'F10' && evt.shiftKey && evt.altKey)) {
      return true;
    }

    evt.preventDefault();
    evt.stopPropagation();

    // Locate the row from event
    const element = target.closest<HTMLTableRowElement>(this.SELECTOR)!;
    const wpId = element.dataset.workPackageId!;

    super.openContextMenu(
      component.workPackageTable,
      evt,
      wpId,
      // Set position args to open at element
      { placement: 'bottom-start', reference: target }
    );

    return false;
  }
}
