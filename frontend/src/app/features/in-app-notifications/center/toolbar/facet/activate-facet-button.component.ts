import { ChangeDetectionStrategy, Component } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import {
  IAN_FACET_FILTERS,
  InAppNotificationFacet,
} from 'core-app/features/in-app-notifications/center/state/ian-center.store';

@Component({
  selector: 'op-activate-facet',
  templateUrl: './activate-facet-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ActivateFacetButtonComponent {
  text = {
    facets: {
      unread: this.I18n.t('js.notifications.facets.unread'),
      all: this.I18n.t('js.notifications.facets.all'),
    },
  };

  availableFacets = Object.keys(IAN_FACET_FILTERS);

  activeFacet$ = this.storeService.query.activeFacet$;

  constructor(
    private I18n:I18nService,
    private storeService:IanCenterService,
  ) {
  }

  activateFacet(facet:InAppNotificationFacet):void {
    this.storeService.setFacet(facet);
  }
}
