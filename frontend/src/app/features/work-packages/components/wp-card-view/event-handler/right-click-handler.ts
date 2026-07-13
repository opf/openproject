import { Injector } from '@angular/core';
import { CardEventHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/card-view-handler-registry';
import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { uiStateLinkClass } from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { WorkPackageCardViewService } from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-view.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageViewContextMenu } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-view-context-menu.directive';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class CardRightClickHandler implements CardEventHandler {
  // Injections
  @LazyInject() wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() wpCardView:WorkPackageCardViewService;

  @LazyInject() opContextMenu:OPContextMenuService;

  constructor(public readonly injector:Injector,
    card:WorkPackageCardViewComponent) {
  }

  public get EVENT():EventType {
    return 'contextmenu'; // N.B.: contextmenu is not supported by Safari on iOS.
  }

  public get SELECTOR() {
    return '[data-test-selector="op-wp-single-card"]';
  }

  public eventScope(card:WorkPackageCardViewComponent) {
    return card.container.nativeElement;
  }

  public handleEvent(card:WorkPackageCardViewComponent, evt:Event) {
    const target = evt.target as HTMLElement;

    // We want to keep the original context menu on hrefs
    // (currently, this is only the id)
    if (target.closest(`.${uiStateLinkClass}`)) {
      debugLog('Allowing original context menu on state link');
      return true;
    }

    evt.preventDefault();
    evt.stopPropagation();

    // Locate the card from event
    const element = target.closest<HTMLElement>('wp-single-card')!;
    const wpId = element.dataset.workPackageId;

    if (!wpId) {
      return true;
    }
    const classIdentifier = element.dataset.classIdentifier!;
    const index = this.wpCardView.findRenderedCard(classIdentifier);

    if (!this.wpTableSelection.isSelected(wpId)) {
      this.wpTableSelection.setSelection(wpId, index);
    }

    const handler = new WorkPackageViewContextMenu(this.injector, wpId, evt.target as HTMLElement, {}, card.showInfoButton);
    this.opContextMenu.show(handler, evt);

    return false;
  }
}
