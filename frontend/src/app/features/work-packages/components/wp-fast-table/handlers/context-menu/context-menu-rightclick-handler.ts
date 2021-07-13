import { Injector } from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { TableEventComponent } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { timelineCellClassName } from '../../builders/timeline/timeline-row-builder';
import { uiStateLinkClass } from '../../builders/ui-state-link-builder';
import { ContextMenuHandler } from './context-menu-handler';

export class ContextMenuRightClickHandler extends ContextMenuHandler {
  @InjectField() readonly wpTableSelection:WorkPackageViewSelectionService;

  constructor(public readonly injector:Injector) {
    super(injector);
  }

  public get EVENT() {
    return 'contextmenu.table.rightclick';
  }

  public get SELECTOR() {
    return `.${tableRowClassName},.${timelineCellClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return jQuery(view.workPackageTable.tableAndTimelineContainer);
  }

  public handleEvent(view:TableEventComponent, evt:JQuery.TriggeredEvent):boolean {
    if (!view.workPackageTable.configuration.contextMenuEnabled) {
      return false;
    }
    const target = jQuery(evt.target);

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
      const [index] = view.workPackageTable.findRenderedRow(wpId);

      if (!this.wpTableSelection.isSelected(wpId)) {
        this.wpTableSelection.setSelection(wpId, index);
      }

      this.openContextMenu(view.workPackageTable, evt, wpId);
    }

    return false;
  }
}
