import {
  ChangeDetectionStrategy,
  Component,
  HostBinding,
  Input,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  Observable,
  timer,
} from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import {
  distinctUntilChanged,
  map,
} from 'rxjs/operators';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { take } from 'rxjs/internal/operators/take';
import { StateService } from '@uirouter/angular';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { InAppNotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import { DeviceService } from 'core-app/core/browser/device.service';

@Component({
  selector: 'op-in-app-notification-entry',
  templateUrl: './in-app-notification-entry.component.html',
  styleUrls: ['./in-app-notification-entry.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class InAppNotificationEntryComponent implements OnInit {
  @HostBinding('class.op-ian-item') className = true;

  @Input() notification:InAppNotification;

  @Input() aggregatedNotifications:InAppNotification[];

  workPackage$:Observable<WorkPackageResource>|null = null;

  loading$ = this.storeService.query.selectLoading();

  stateChanged$ = this.storeService.stateChanged$;

  // The actor, if any
  actors:PrincipalLike[] = [];

  // The translated reason, if available
  translatedReasons:{ [reason:string]:number };

  // Format relative elapsed time (n seconds/minutes/hours ago)
  // at an interval for auto updating
  relativeTime$:Observable<string>;

  fixedTime:string;

  project?:{ href:string, title:string, showUrl:string };

  text = {
    and_other_singular: this.I18n.t('js.notifications.center.and_more_users.one'),
    and_other_plural: (count:number):string => this.I18n.t('js.notifications.center.and_more_users.other',
      { count }),
    loading: this.I18n.t('js.ajax.loading'),
    placeholder: this.I18n.t('js.placeholders.default'),
    updated_by_at: (age:string):string => this.I18n.t('js.notifications.center.text_update_date',
      { date: age }),
  };

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly I18n:I18nService,
    readonly storeService:IanCenterService,
    readonly timezoneService:TimezoneService,
    readonly pathHelper:PathHelperService,
    readonly state:StateService,
    readonly deviceService:DeviceService,
  ) {
  }

  ngOnInit():void {
    this.buildTranslatedReason();
    this.buildActors();
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

  private buildTime() {
    this.fixedTime = this.timezoneService.formattedDatetime(this.notification.createdAt);
    this.relativeTime$ = timer(0, 10000)
      .pipe(
        map(() => this.text.updated_by_at(
          this.timezoneService.formattedRelativeDateTime(this.notification.createdAt),
        )),
        distinctUntilChanged(),
      );
  }

  showDetails():void {
    if (!this.workPackage$) {
      return;
    }

    this
      .workPackage$
      .pipe(
        take(1),
      )
      .subscribe((wp) => {
        this.storeService.openSplitScreen(wp.id);
      });
  }

  projectClicked(event:MouseEvent):void { // eslint-disable-line class-methods-use-this
    event.stopPropagation();
  }

  markAsRead(event:MouseEvent, notifications:InAppNotification[]):void {
    event.stopPropagation();
    this.storeService.markAsRead(notifications.map((el) => el.id));
  }

  text_for_additional_authors(number:number):string {
    let hint:string;
    if (number === 1) {
      hint = this.text.and_other_singular;
    } else {
      hint = this.text.and_other_plural(number);
    }
    return hint;
  }

  isMobile():boolean {
    return this.deviceService.isMobile;
  }

  private buildActors() {
    const actors = this
      .aggregatedNotifications
      .map((notification) => {
        const { actor } = notification._links;

        if (!actor) {
          return null;
        }

        return {
          href: actor.href,
          name: actor.title,
        };
      })
      .filter((actor) => actor !== null) as PrincipalLike[];

    this.actors = _.uniqBy(actors, (item) => item.href);
  }

  private buildTranslatedReason() {
    const reasons:{ [reason:string]:number } = {};

    this
      .aggregatedNotifications
      .forEach((notification) => {
        const translatedReason = this.I18n.t(
          `js.notifications.reasons.${notification.reason}`,
          { defaultValue: notification.reason || this.text.placeholder },
        );

        reasons[translatedReason] = reasons[translatedReason] || 0;
        reasons[translatedReason] += 1;
      });

    this.translatedReasons = reasons;
  }

  private buildProject() {
    const { project } = this.notification._links;

    if (project) {
      this.project = {
        ...project,
        showUrl: this.pathHelper.projectPath(idFromLink(project.href)),
      };
    }
  }
}
