import { ChangeDetectionStrategy, Component } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Actions } from '@datorama/akita-ng-effects';
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

  activeFacet$ = this.storeService.activeFacet$;

  constructor(
    private I18n:I18nService,
    private storeService:IanCenterService,
    private actions$:Actions,
  ) {
  }

  activateFacet(facet:InAppNotificationFacet):void {
    this.storeService.setFacet(facet);
  }
}
