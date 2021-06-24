import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import {
  InAppNotification,
  InAppNotificationDetail
} from "core-app/features/in-app-notifications/store/in-app-notification.model";
import { WorkPackageResource } from "core-app/features/hal/resources/work-package-resource";
import { NEVER, Observable, timer } from "rxjs";
import { APIV3Service } from "core-app/core/apiv3/api-v3.service";
import { HalResource } from "core-app/features/hal/resources/hal-resource";
import { I18nService } from "core-app/core/i18n/i18n.service";
import { InAppNotificationsService } from "core-app/features/in-app-notifications/store/in-app-notifications.service";
import { TimezoneService } from "core-app/core/datetime/timezone.service";
import { distinctUntilChanged, map, mapTo } from "rxjs/operators";

@Component({
  selector: 'op-in-app-notification-entry',
  templateUrl: './in-app-notification-entry.component.html',
  styleUrls: ['./in-app-notification-entry.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class InAppNotificationEntryComponent implements OnInit {
  @Input() notification:InAppNotification;

  workPackage$:Observable<WorkPackageResource>|null = null;

  // Formattable body, if any
  body:InAppNotificationDetail[];

  // custom rendered details, if any
  details:InAppNotificationDetail[];

  // Format relative elapsed time (n seconds/minutes/hours ago)
  // at an interval for auto updating
  relativeTime$:Observable<string>;
  fixedTime:string;

  text = {
    loading: this.I18n.t('js.ajax.loading'),
  };

  constructor(
    readonly apiV3Service:APIV3Service,
    readonly I18n:I18nService,
    readonly inAppNotificationsService:InAppNotificationsService,
    readonly timezoneService:TimezoneService,
  ) {
  }

  ngOnInit():void {
    const href = this.notification._links.resource?.href;
    const id = href && HalResource.matchFromLink(href, 'work_packages');

    const details = this.notification.details || [];
    this.body = details.filter(el => el.format === 'markdown');
    this.details = details.filter(el => el.format === 'custom');

    this.fixedTime = this.timezoneService.formattedDatetime(this.notification.updatedAt);
    this.relativeTime$ = timer(0, 10000)
      .pipe(
        map(() => this.timezoneService.formattedRelativeDateTime(this.notification.updatedAt)),
        distinctUntilChanged()
      );

    // Not a work package reference
    if (id) {
      this.workPackage$ = this
        .apiV3Service
        .work_packages
        .id(id)
        .requireAndStream();
    }
  }

  toggleDetails():void {
    if (!this.notification.read) {
      this.inAppNotificationsService.markReadKeepAndExpanded(this.notification);
    }
    if (this.notification.expanded) {
      this.inAppNotificationsService.collapse(this.notification);
    } else {
      this.inAppNotificationsService.expand(this.notification);
    }
  }
}
