import {Injector} from '@angular/core';
import {CardEventHandler} from "core-components/wp-card-view/event-handler/card-view-handler-registry";
import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import {uiStateLinkClass} from "core-components/wp-fast-table/builders/ui-state-link-builder";
import {debugLog} from "core-app/helpers/debug_output";
import {WorkPackageCardViewService} from "core-components/wp-card-view/services/wp-card-view.service";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {WorkPackageViewContextMenu} from "core-components/op-context-menu/wp-context-menu/wp-view-context-menu.directive";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

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
    return `.wp-card`;
  }

  public eventScope(card:WorkPackageCardViewComponent) {
    return jQuery(card.container.nativeElement);
  }

  public handleEvent(card:WorkPackageCardViewComponent, evt:JQuery.TriggeredEvent) {
    let target = jQuery(evt.target);

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
    } else {
      let classIdentifier = element.data('classIdentifier');
      let index = this.wpCardView.findRenderedCard(classIdentifier);

      if (!this.wpTableSelection.isSelected(wpId)) {
        this.wpTableSelection.setSelection(wpId, index);
      }

      const handler = new WorkPackageViewContextMenu(this.injector, wpId, jQuery(evt.target) as JQuery, {}, card.showInfoButton);
      this.opContextMenu.show(handler, evt);
    }

    return false;
  }
}

