import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { CardClickHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/click-handler';
import { CardDblClickHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/double-click-handler';
import { CardRightClickHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/right-click-handler';
import {
  WorkPackageViewEventHandler,
  WorkPackageViewHandlerRegistry,
} from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export type CardEventHandler = WorkPackageViewEventHandler<WorkPackageCardViewComponent>;

export class CardViewHandlerRegistry extends WorkPackageViewHandlerRegistry<WorkPackageCardViewComponent> {
  protected eventHandlers:((c:WorkPackageCardViewComponent) => CardEventHandler)[] = [
    // Clicking on the card (not within a cell)
    (c) => new CardClickHandler(this.injector, c),
    // Double Clicking on the row (not within a cell)
    (c) => new CardDblClickHandler(this.injector, c),
    // Right clicking on cards
    (t) => new CardRightClickHandler(this.injector, t),
  ];
}
