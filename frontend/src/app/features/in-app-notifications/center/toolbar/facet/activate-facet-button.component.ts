import { Component, ChangeDetectionStrategy } from '@angular/core';
import { IAN_FACETS } from 'core-app/features/in-app-notifications/store/in-app-notification.model';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';

@Component({
  selector: 'op-activate-facet',
  templateUrl: './activate-facet-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ActivateFacetButtonComponent {
  activeFacet$ = this.ianQuery.activeFacet$;

  text = {
    facets: {
      unread: this.I18n.t('js.notifications.facets.unread'),
      all: this.I18n.t('js.notifications.facets.all'),
    },
  };

  availableFacets = IAN_FACETS;

  constructor(
    private I18n:I18nService,
    private ianQuery:InAppNotificationsQuery,
    private ianService:InAppNotificationsService,
  ) {
  }

  activateFacet(facet:string):void {
    this.ianService.setActiveFacet(facet);
  }
}
