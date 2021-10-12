import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  filter,
  map,
} from 'rxjs/operators';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import {
  InAppNotification,
  NOTIFICATIONS_MAX_SIZE,
} from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { UIRouterGlobals } from '@uirouter/core';

@Component({
  selector: 'op-in-app-notification-center',
  templateUrl: './in-app-notification-center.component.html',
  styleUrls: ['./in-app-notification-center.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterComponent implements OnInit {
  maxSize = NOTIFICATIONS_MAX_SIZE;

  hasMoreThanPageSize$ = this.storeService.query.hasMoreThanPageSize$;

  hasNotifications$ = this.storeService.query.hasNotifications$;

  notifications$ = this.storeService.query.notifications$;

  loading$ = this.storeService.query.selectLoading();

  noResultText$ = this
    .storeService
    .query
    .activeFacet$
    .pipe(
      map((facet:'unread'|'all') => this.text.no_results[facet] || this.text.no_results.unread),
    );

  totalCountWarning$ = this
    .storeService
    .query
    .notLoaded$
    .pipe(
      filter((notLoaded) => notLoaded > 0),
      map((notLoaded:number) => this.I18n.t(
        'js.notifications.center.total_count_warning',
        { newest_count: this.maxSize, more_count: notLoaded },
      )),
    );

  stateChanged$ = this.storeService.stateChanged$;

  originalOrder = ():number => 0;

  trackNotificationGroups = (i:number, item:InAppNotification[]):string => item
    .map((el) => `${el.id}@${el.updatedAt}`)
    .join(',');

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
    readonly storeService:IanCenterService,
    readonly uiRouterGlobals:UIRouterGlobals,
  ) {
  }

  ngOnInit():void {
    this.storeService.setFacet('unread');
    this.storeService.setFilters({
      filter: this.uiRouterGlobals.params.filter, // eslint-disable-line @typescript-eslint/no-unsafe-assignment
      name: this.uiRouterGlobals.params.name, // eslint-disable-line @typescript-eslint/no-unsafe-assignment
    });
  }
}
