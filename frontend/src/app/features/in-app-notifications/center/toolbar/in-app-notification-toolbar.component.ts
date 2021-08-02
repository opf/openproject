import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';
import { IAN_FACETS } from 'core-app/features/in-app-notifications/store/in-app-notification.model';

@Component({
  selector: 'op-ian-center-toolbar',
  templateUrl: './in-app-notification-toolbar.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationToolbarComponent {
  activeFacet$ = this.ianQuery.activeFacet$

  text = {
    title: this.I18n.t('js.notifications.title'),
    my_settings: this.I18n.t('js.notifications.settings.title'),
    mark_all_read: this.I18n.t('js.notifications.center.mark_all_read'),
    facets: {
      unread: this.I18n.t('js.notifications.facets.unread'),
      all: this.I18n.t('js.notifications.facets.all'),
    },
  };

  myNotificationSettingsLink = this.pathHelper.myNotificationsSettingsPath();

  availableFacets = IAN_FACETS;

  constructor(
    private I18n:I18nService,
    private pathHelper:PathHelperService,
    private ianQuery:InAppNotificationsQuery,
    private ianService:InAppNotificationsService,
  ) {
  }

  markAllRead():void {
    this.ianService.markAllRead();
  }

  activateFacet(facet:string):void {
    this.ianService.setActiveFacet(facet);
    this.ianService.get();
  }
}
