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
import { StateService } from '@uirouter/angular';
import { UIRouterGlobals } from '@uirouter/core';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import {
  InAppNotification,
  NOTIFICATIONS_MAX_SIZE,
} from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';

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

  private totalCount$ = this.bellService.unread$;

  noResultText$ = this
    .totalCount$
    .pipe(
      map((count:number) => (count > 0 ? this.text.no_results.with_current_filter : this.text.no_results.at_all)),
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
    change_notification_settings: this.I18n.t(
      'js.notifications.settings.change_notification_settings',
      { url: this.pathService.myNotificationsSettingsPath() },
    ),
    title: this.I18n.t('js.notifications.title'),
    button_close: this.I18n.t('js.button_close'),
    no_results: {
      at_all: this.I18n.t('js.notifications.center.no_results.at_all'),
      with_current_filter: this.I18n.t('js.notifications.center.no_results.with_current_filter'),
    },
  };

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly I18n:I18nService,
    readonly storeService:IanCenterService,
    readonly bellService:IanBellService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly state:StateService,
    readonly apiV3:ApiV3Service,
    readonly pathService:PathHelperService,
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
