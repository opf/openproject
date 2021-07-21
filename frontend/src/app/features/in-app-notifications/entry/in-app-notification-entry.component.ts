import {
  EventEmitter, ChangeDetectionStrategy, Component, Input, OnInit, Output,
} from '@angular/core';
import {
  InAppNotification,
  InAppNotificationDetail,
} from 'core-app/features/in-app-notifications/store/in-app-notification.model';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { Observable, timer } from 'rxjs';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { distinctUntilChanged, map } from 'rxjs/operators';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Component({
  selector: 'op-in-app-notification-entry',
  templateUrl: './in-app-notification-entry.component.html',
  styleUrls: ['./in-app-notification-entry.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationEntryComponent implements OnInit {
  @Input() notification:InAppNotification;

  @Output() resourceLinkClicked = new EventEmitter<unknown>();

  workPackage$:Observable<WorkPackageResource>|null = null;

  // Formattable body, if any
  body:InAppNotificationDetail[];

  // custom rendered details, if any
  details:InAppNotificationDetail[];

  // The actor, if any
  actor?:PrincipalLike;

  // The translated reason, if available
  translatedReason?:string;

  // Format relative elapsed time (n seconds/minutes/hours ago)
  // at an interval for auto updating
  relativeTime$:Observable<string>;

  fixedTime:string;

  project?:{ href:string, title:string, showUrl:string };

  text = {
    loading: this.I18n.t('js.ajax.loading'),
    placeholder: this.I18n.t('js.placeholders.default'),
  };

  constructor(
    readonly apiV3Service:APIV3Service,
    readonly I18n:I18nService,
    readonly inAppNotificationsService:InAppNotificationsService,
    readonly timezoneService:TimezoneService,
    readonly pathHelper:PathHelperService,
  ) {
  }

  ngOnInit():void {
    this.buildTranslatedReason();
    this.buildActor();
    this.buildDetails();
    this.buildTime();
    this.buildProject();
    this.loadWorkPackage();
  }

  private loadWorkPackage() {
    const href = this.notification._links.resource?.href;
    const id = href && HalResource.matchFromLink(href, 'work_packages');
    // not a work package reference
    if (id) {
      this.workPackage$ = this
        .apiV3Service
        .work_packages
        .id(id)
        .requireAndStream();
    }
  }

  private buildDetails() {
    const details = this.notification.details || [];
    this.body = details.filter((el) => el.format === 'markdown');
    this.details = details.filter((el) => el.format === 'custom');
  }

  private buildTime() {
    this.fixedTime = this.timezoneService.formattedDatetime(this.notification.createdAt);
    this.relativeTime$ = timer(0, 10000)
      .pipe(
        map(() => this.timezoneService.formattedRelativeDateTime(this.notification.createdAt)),
        distinctUntilChanged(),
      );
  }

  toggleDetails():void {
    if (!this.notification.readIAN) {
      this.inAppNotificationsService.markReadKeepAndExpanded(this.notification);
    }
    if (this.notification.expanded) {
      this.inAppNotificationsService.collapse(this.notification);
    } else {
      this.inAppNotificationsService.expand(this.notification);
    }
  }

  private buildActor() {
    const { actor } = this.notification._links;

    if (actor) {
      this.actor = {
        href: actor.href,
        name: actor.title,
      };
    }
  }

  private buildTranslatedReason() {
    this.translatedReason = this.I18n.t(
      `js.notifications.reasons.${this.notification.reason}`,
      { defaultValue: this.notification.reason || this.text.placeholder },
    );
  }

  projectClicked(event:MouseEvent) {
    event.stopPropagation();
  }

  private buildProject() {
    const { project } = this.notification._links;

    if (project) {
      this.project = {
        ...project,
        showUrl: this.pathHelper.projectPath(HalResource.idFromLink(project.href)),
      };
    }
  }
}
