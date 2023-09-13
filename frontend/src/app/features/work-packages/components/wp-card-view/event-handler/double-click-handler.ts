import { Injector } from '@angular/core';
import { CardEventHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/card-view-handler-registry';
import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { StateService } from '@uirouter/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

export class CardDblClickHandler implements CardEventHandler {
  @InjectField() $state:StateService;

  @InjectField() wpTableSelection:WorkPackageViewSelectionService;

  constructor(public readonly injector:Injector,
    card:WorkPackageCardViewComponent) {
  }

  public get EVENT() {
    return 'dblclick.cardView.card';
  }

  public get SELECTOR() {
    return `[data-test-selector="op-wp-single-card"]`;
  }

  public eventScope(card:WorkPackageCardViewComponent) {
    return jQuery(card.container.nativeElement);
  }

  public handleEvent(card:WorkPackageCardViewComponent, evt:JQuery.TriggeredEvent) {
    const target = jQuery(evt.target);

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    // Locate the row from event
    const element = target.closest('wp-single-card');
    const wpId = element.data('workPackageId');

    if (!wpId) {
      return true;
    }

    card.itemClicked.emit({ workPackageId: wpId, double: true });
    return false;
  }
}
