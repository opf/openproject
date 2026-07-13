import { Injector } from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { TableEventComponent } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { timelineCellClassName } from '../../builders/timeline/timeline-row-builder';
import { uiStateLinkClass } from '../../builders/ui-state-link-builder';
import { ContextMenuHandler } from './context-menu-handler';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class ContextMenuRightClickHandler extends ContextMenuHandler {
  @LazyInject() readonly wpTableSelection:WorkPackageViewSelectionService;

  constructor(public readonly injector:Injector) {
    super(injector);
  }

  public get EVENT():EventType {
    return 'contextmenu'; // N.B.: contextmenu is not supported by Safari on iOS.
  }

  public get SELECTOR() {
    return `.${tableRowClassName},.${timelineCellClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tableAndTimelineContainer;
  }

  public handleEvent(view:TableEventComponent, evt:Event):boolean {
    if (!view.workPackageTable.configuration.contextMenuEnabled) {
      return false;
    }
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
    const element = target.closest<HTMLElement>(this.SELECTOR);
    const wpId = element?.dataset.workPackageId;

    if (wpId) {
      const [index] = view.workPackageTable.findRenderedRow(wpId);

      if (!this.wpTableSelection.isSelected(wpId)) {
        this.wpTableSelection.setSelection(wpId, index);
      }

      this.openContextMenu(view.workPackageTable, evt, wpId);
    }

    return false;
  }
}
