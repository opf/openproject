import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  distinctUntilChanged,
  filter,
  map,
  pluck,
  share,
} from 'rxjs/operators';
import { StateService } from '@uirouter/angular';
import { UIRouterGlobals } from '@uirouter/core';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import {
  InAppNotification,
  NOTIFICATIONS_MAX_SIZE,
} from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';

@Component({
  selector: 'op-in-app-notification-center',
  templateUrl: './in-app-notification-center.component.html',
  styleUrls: ['./in-app-notification-center.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterComponent extends UntilDestroyedMixin implements OnInit {
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

  stateChanged$ = this.uiRouterGlobals.params$?.pipe(
    this.untilDestroyed(),
    pluck('workPackageId'),
    distinctUntilChanged(),
    map((workPackageId:string) => (workPackageId ? this.apiV3.work_packages.id(workPackageId).path : undefined)),
    share(),
  );

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

  selectedNotification:InAppNotification|undefined;

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly I18n:I18nService,
    readonly storeService:IanCenterService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly state:StateService,
    readonly apiV3:APIV3Service,
  ) {
    super();
  }

  ngOnInit():void {
    this.storeService.setFacet('unread');
  }
}
