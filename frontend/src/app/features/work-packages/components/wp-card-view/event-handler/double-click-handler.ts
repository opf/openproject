import { Injector } from '@angular/core';
import { CardEventHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/card-view-handler-registry';
import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { StateService } from '@uirouter/core';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class CardDblClickHandler implements CardEventHandler {
  @LazyInject() $state:StateService;

  @LazyInject() wpTableSelection:WorkPackageViewSelectionService;

  constructor(public readonly injector:Injector,
    card:WorkPackageCardViewComponent) {
  }

  public get EVENT():EventType {
    return 'dblclick';
  }

  public get SELECTOR() {
    return '[data-test-selector="op-wp-single-card"]';
  }

  public eventScope(card:WorkPackageCardViewComponent) {
    return card.container.nativeElement;
  }

  public handleEvent(card:WorkPackageCardViewComponent, evt:Event) {
    const target = evt.target as HTMLElement;

    // Ignore links
    if (target instanceof HTMLAnchorElement || target.parentElement instanceof HTMLAnchorElement) {
      return true;
    }

    // Locate the row from event
    const element = target.closest<HTMLElement>('wp-single-card')!;
    const wpId = element.dataset.workPackageId;

    if (!wpId) {
      return true;
    }

    card.itemClicked.emit({ workPackageId: wpId, double: true });
    return false;
  }
}
