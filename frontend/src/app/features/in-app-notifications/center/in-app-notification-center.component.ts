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
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { UIRouterGlobals } from '@uirouter/core';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import { NOTIFICATIONS_MAX_SIZE } from 'core-app/core/state/in-app-notifications/in-app-notification.model';

@Component({
  selector: 'op-in-app-notification-center',
  templateUrl: './in-app-notification-center.component.html',
  styleUrls: ['./in-app-notification-center.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterComponent implements OnInit {
  maxSize = NOTIFICATIONS_MAX_SIZE;

  activeFacet$ = this.storeService.activeFacet$;

  notifications$ = this
    .storeService
    .aggregatedCenterNotifications$
    .pipe(
      map((items) => Object.values(items)),
    );

  hasNotifications$ = this
    .notifications$
    .pipe(
      map((items) => items.length > 0),
    );

  hasMoreThanPageSize$ = this
    .storeService
    .notLoaded$
    .pipe(
      map((notLoaded) => notLoaded > 0),
    );

  noResultText$ = this
    .activeFacet$
    .pipe(
      map((facet:'unread'|'all') => this.text.no_results[facet] || this.text.no_results.unread),
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

  originalOrder = ():number => 0;

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
    readonly state:StateService,
  ) { }

  ngOnInit():void {
    this.storeService.setFacet('unread');
  }

  openSplitView($event:WorkPackageResource):void {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    const baseRoute = this.uiRouterGlobals.current.data.baseRoute as string;
    void this.state.go(`${baseRoute}.details`, { workPackageId: $event.id });
  }
}
