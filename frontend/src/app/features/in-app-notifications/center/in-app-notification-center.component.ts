import {
  AfterContentInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { NOTIFICATIONS_MAX_SIZE } from 'core-app/features/in-app-notifications/store/in-app-notification.model';
import { map } from 'rxjs/operators';
import { StateService } from '@uirouter/angular';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { UIRouterGlobals } from '@uirouter/core';

@Component({
  selector: 'op-in-app-notification-center',
  templateUrl: './in-app-notification-center.component.html',
  styleUrls: ['./in-app-notification-center.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterComponent implements OnInit, AfterContentInit {
  activeFacet$ = this.ianQuery.activeFacet$;

  notifications$ = this
    .ianService
    .query
    .aggregatedNotifications$
    .pipe(
      map((items) => Object.values(items)),
    );

  hasNotifications$ = this.ianService.query.hasNotifications$;

  hasMoreThanPageSize$ = this.ianService.query.hasMoreThanPageSize$;

  noResultText$ = this
  .activeFacet$
  .pipe(
    map((facet:'unread'|'all') => this.text.no_results[facet] || this.text.no_results.unread),
  );

  totalCountWarning$ = this
    .ianService
    .query
    .notLoaded$
    .pipe(
      map((notLoaded:number) => this.I18n.t(
        'js.notifications.center.total_count_warning',
        { newest_count: NOTIFICATIONS_MAX_SIZE, more_count: notLoaded },
      )),
    );

  isNoticationsLoaded = false;

  maxSize = NOTIFICATIONS_MAX_SIZE;

  facets:string[] = ['unread', 'all'];

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
    readonly ianService:InAppNotificationsService,
    readonly ianQuery:InAppNotificationsQuery,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly state:StateService,
  ) { }

  ngOnInit():void {
    this.ianService.setActiveFacet('unread');
    this.ianService.setActiveFilters([]);
  }

  ngAfterContentInit():void {
    setTimeout(() => {
      this.isNoticationsLoaded = true;
    });
  }

  openSplitView($event:WorkPackageResource):void {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    const baseRoute = this.uiRouterGlobals.current.data.baseRoute as string;
    void this.state.go(`${baseRoute}.details`, { workPackageId: $event.id });
  }
}
