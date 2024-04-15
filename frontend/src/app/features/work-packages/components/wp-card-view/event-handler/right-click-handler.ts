import { Injector } from '@angular/core';
import { CardEventHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/card-view-handler-registry';
import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { uiStateLinkClass } from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { WorkPackageCardViewService } from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-view.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageViewContextMenu } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-view-context-menu.directive';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

export class CardRightClickHandler implements CardEventHandler {
  // Injections
  @InjectField() wpTableSelection:WorkPackageViewSelectionService;

  @InjectField() wpCardView:WorkPackageCardViewService;

  @InjectField() opContextMenu:OPContextMenuService;

  constructor(public readonly injector:Injector,
    card:WorkPackageCardViewComponent) {
  }

  public get EVENT() {
    return 'contextmenu.cardView.rightclick';
  }

  public get SELECTOR() {
    return `[data-test-selector="op-wp-single-card"]`;
  }

  public eventScope(card:WorkPackageCardViewComponent) {
    return jQuery(card.container.nativeElement);
  }

  public handleEvent(card:WorkPackageCardViewComponent, evt:JQuery.TriggeredEvent) {
    const target = jQuery(evt.target);

    // We want to keep the original context menu on hrefs
    // (currently, this is only the id)
    if (target.closest(`.${uiStateLinkClass}`).length) {
      debugLog('Allowing original context menu on state link');
      return true;
    }

    evt.preventDefault();
    evt.stopPropagation();

    // Locate the card from event
    const element = target.closest('wp-single-card');
    const wpId = element.data('workPackageId');

    if (!wpId) {
      return true;
    }
    const classIdentifier = element.data('classIdentifier');
    const index = this.wpCardView.findRenderedCard(classIdentifier);

    if (!this.wpTableSelection.isSelected(wpId)) {
      this.wpTableSelection.setSelection(wpId, index);
    }

    const handler = new WorkPackageViewContextMenu(this.injector, wpId, jQuery(evt.target) as JQuery, {}, card.showInfoButton);
    this.opContextMenu.show(handler, evt);

    return false;
  }
}
