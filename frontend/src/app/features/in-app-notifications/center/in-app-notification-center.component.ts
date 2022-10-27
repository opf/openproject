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
  INotification,
  NOTIFICATIONS_MAX_SIZE,
} from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';

@Component({
  selector: 'op-in-app-notification-center',
  templateUrl: './in-app-notification-center.component.html',
  styleUrls: ['./in-app-notification-center.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterComponent implements OnInit {
  maxSize = NOTIFICATIONS_MAX_SIZE;

  hasMoreThanPageSize$ = this.storeService.hasMoreThanPageSize$;

  hasNotifications$ = this.storeService.hasNotifications$;

  notifications$ = this.storeService.notifications$;

  loading$ = this.storeService.loading$;

  private totalCount$ = this.bellService.unread$;

  noResultText$ = this
    .totalCount$
    .pipe(
      map((count:number) => (count > 0 ? this.text.no_results.with_current_filter : this.text.no_results.at_all)),
    );

  totalCountWarning$ = this
    .storeService
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

  reasonMenuItems = [
    {
      key: 'mentioned',
      title: this.I18n.t('js.notifications.menu.mentioned'),
    },
    {
      key: 'assigned',
      title: this.I18n.t('js.label_assignee'),
    },
    {
      key: 'responsible',
      title: this.I18n.t('js.notifications.menu.accountable'),
    },
    {
      key: 'watched',
      title: this.I18n.t('js.notifications.menu.watched'),
    },
    {
      key: 'date_alert',
      title: this.I18n.t('js.notifications.menu.date_alert'),
    },
  ];

  selectedFilter = this.reasonMenuItems.find((item) => item.key === this.uiRouterGlobals.params.name)?.title;

  image = {
    no_notification: imagePath('notification-center/empty-state-no-notification.svg'),
    no_selection: imagePath('notification-center/empty-state-no-selection.svg'),
    loading: imagePath('notification-center/notification_loading.gif'),
  };

  trackNotificationGroups = (i:number, item:INotification[]):string => item
    .map((el) => `${el.id}@${el.updatedAt}`)
    .join(',');

  text = {
    no_notification: this.I18n.t('js.notifications.center.empty_state.no_notification'),
    no_notification_with_current_filter_project: this.I18n.t('js.notifications.center.empty_state.no_notification_with_current_project_filter'),
    no_notification_with_current_filter: this.I18n.t('js.notifications.center.empty_state.no_notification_with_current_filter', { filter: this.selectedFilter }),
    no_selection: this.I18n.t('js.notifications.center.empty_state.no_selection'),
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

  noNotificationText(hasNotifications:boolean, totalNotifications:number):string {
    if (!(!hasNotifications && totalNotifications > 0)) {
      return this.text.no_notification;
    }
    return (this.uiRouterGlobals.params.filter === 'project' ? this.text.no_notification_with_current_filter_project : this.text.no_notification_with_current_filter);
  }
}
