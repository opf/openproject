import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject, OnInit,
} from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';
import { NOTIFICATIONS_MAX_SIZE } from 'core-app/features/in-app-notifications/store/in-app-notification.model';

@Component({
  selector: 'op-in-app-notification-center',
  templateUrl: './in-app-notification-center.component.html',
  styleUrls: ['./in-app-notification-center.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterComponent extends OpModalComponent implements OnInit {
  activeFacet$ = this.ianQuery.activeFacet$;

  notifications$ = this.ianQuery.selectAll();

  notificationsCount$ = this.ianQuery.selectCount();

  hasNotifications$ = this.ianQuery.hasNotifications$;

  hasMoreThanPageSize$ = this.ianQuery.hasMoreThanPageSize$;

  maxSize = NOTIFICATIONS_MAX_SIZE;

  facets:string[] = ['unread', 'all'];

  text = {
    title: this.I18n.t('js.notifications.title'),
    mark_all_read: this.I18n.t('js.notifications.center.mark_all_read'),
    button_close: this.I18n.t('js.button_close'),
    no_results: this.I18n.t('js.notice_no_results_to_display'),
    facets: {
      unread: this.I18n.t('js.notifications.facets.unread'),
      all: this.I18n.t('js.notifications.facets.all'),
    },
  };

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly I18n:I18nService,
    readonly ianService:InAppNotificationsService,
    readonly ianQuery:InAppNotificationsQuery,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    this.ianService.get();
  }

  markAllRead() {
    this.ianService.markAllRead();
    this.closeMe();
  }

  activateFacet(facet:string) {
    this.ianService.setActiveFacet(facet);
    this.ianService.get();
  }

  totalCountWarning() {
    const state = this.ianQuery.getValue();

    return this.I18n.t(
      'js.notifications.center.total_count_warning',
      { newest_count: NOTIFICATIONS_MAX_SIZE, more_count: state.notShowing },
    );
  }
}
