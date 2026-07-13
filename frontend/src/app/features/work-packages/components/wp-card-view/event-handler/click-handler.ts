import { Injector } from '@angular/core';
import { CardEventHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/card-view-handler-registry';
import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageCardViewService } from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-view.service';
import { StateService } from '@uirouter/core';
import { DeviceService } from 'core-app/core/browser/device.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class CardClickHandler implements CardEventHandler {
  // Injections
  @LazyInject() deviceService:DeviceService;

  @LazyInject() $state:StateService;

  @LazyInject() wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() wpTableFocus:WorkPackageViewFocusService;

  @LazyInject() wpCardView:WorkPackageCardViewService;

  constructor(public readonly injector:Injector,
    card:WorkPackageCardViewComponent) {
  }

  public get EVENT():EventType {
    return 'click';
  }

  public get SELECTOR() {
    return '[data-test-selector="op-wp-single-card"]';
  }

  public eventScope(card:WorkPackageCardViewComponent) {
    return card.container.nativeElement;
  }

  public handleEvent(card:WorkPackageCardViewComponent, evt:MouseEvent) {
    const target = evt.target as HTMLElement;

    // Ignore links
    if (target instanceof HTMLAnchorElement || target.parentElement instanceof HTMLAnchorElement) {
      return true;
    }

    // Locate the card from event
    const element = target.closest<HTMLElement>('wp-single-card')!;
    const wpId = element.dataset.workPackageId;

    if (!wpId) {
      return true;
    }

    this.handleWorkPackage(card, wpId, element, evt);

    return false;
  }

  protected handleWorkPackage(card:WorkPackageCardViewComponent, wpId:any, element:HTMLElement, evt:MouseEvent) {
    this.setSelection(card, wpId, element, evt);

    card.itemClicked.emit({ workPackageId: wpId, double: false });
  }

  protected setSelection(card:WorkPackageCardViewComponent, wpId:string, element:HTMLElement, evt:MouseEvent) {
    const classIdentifier = element.dataset.classIdentifier!;
    const index = this.wpCardView.findRenderedCard(classIdentifier);

    // Update single selection if no modifier present
    if (!(evt.ctrlKey || evt.metaKey || evt.shiftKey)) {
      this.wpTableSelection.setSelection(wpId, index);
    }

    // Multiple selection if shift present
    if (evt.shiftKey) {
      this.wpTableSelection.setMultiSelectionFrom(this.wpCardView.renderedCards, wpId, index);
    }

    // Single selection expansion if ctrl / cmd(mac)
    if (evt.ctrlKey || evt.metaKey) {
      this.wpTableSelection.toggleRow(wpId);
    }

    card.selectionChanged.emit(this.wpTableSelection.getSelectedWorkPackageIds());

    // The current card is the last selected work package
    // not matter what other card are (de-)selected below.
    // Thus save that card for the details view button.
    this.wpTableFocus.updateFocus(wpId);
  }
}
