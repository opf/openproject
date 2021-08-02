import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';
import { NOTIFICATIONS_MAX_SIZE } from 'core-app/features/in-app-notifications/store/in-app-notification.model';
import { map } from 'rxjs/operators';

@Component({
  selector: 'op-in-app-notification-center',
  templateUrl: './in-app-notification-center.component.html',
  styleUrls: ['./in-app-notification-center.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterComponent implements OnInit {
  activeFacet$ = this.ianQuery.activeFacet$;

  notifications$ = this.ianQuery.selectAll();

  notificationsCount$ = this.ianQuery.selectCount();

  hasNotifications$ = this.ianQuery.hasNotifications$;

  hasMoreThanPageSize$ = this.ianQuery.hasMoreThanPageSize$;

  noResultText$ = this
    .activeFacet$
    .pipe(
      map((facet:'unread'|'all') => this.text.no_results[facet] || this.text.no_results.unread),
    );

  maxSize = NOTIFICATIONS_MAX_SIZE;

  facets:string[] = ['unread', 'all'];

  text = {
    title: this.I18n.t('js.notifications.title'),
    button_close: this.I18n.t('js.button_close'),
    no_results: {
      unread: this.I18n.t('js.notifications.no_unread'),
      all: this.I18n.t('js.notice_no_results_to_display'),
    },
  };

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly I18n:I18nService,
    readonly ianService:InAppNotificationsService,
    readonly ianQuery:InAppNotificationsQuery,
  ) {
  }

  ngOnInit():void {
    this.ianService.get();
  }

  totalCountWarning():string {
    const state = this.ianQuery.getValue();

    return this.I18n.t(
      'js.notifications.center.total_count_warning',
      { newest_count: NOTIFICATIONS_MAX_SIZE, more_count: state.notShowing },
    );
  }
}
