import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnInit,
} from '@angular/core';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';
import {
  Observable,
  timer,
} from 'rxjs';
import {
  distinctUntilChanged,
  map,
} from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DeviceService } from 'core-app/core/browser/device.service';

@Component({
  selector: 'op-in-app-notification-actors-line',
  templateUrl: './in-app-notification-actors-line.component.html',
  styleUrls: ['./in-app-notification-actors-line.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationActorsLineComponent implements OnInit {
  @Input() aggregatedNotifications:INotification[];

  @Input() notification:INotification;

  // The actor, if any
  actors:PrincipalLike[] = [];

  // Fixed notification time
  fixedTime:string;

  // Format relative elapsed time (n seconds/minutes/hours ago)
  // at an interval for auto updating
  relativeTime$:Observable<string>;

  text = {
    and: this.I18n.t('js.notifications.center.label_actor_and'),
    and_other_singular: this.I18n.t('js.notifications.center.and_more_users.one'),
    and_other_plural: (count:number):string => this.I18n.t('js.notifications.center.and_more_users.other',
      { count }),
    loading: this.I18n.t('js.ajax.loading'),
    placeholder: this.I18n.t('js.placeholders.default'),
    mark_as_read: this.I18n.t('js.notifications.center.mark_as_read'),
    updated_by_at: (age:string):string => this.I18n.t('js.notifications.center.text_update_date',
      { date: age }),
  };

  constructor(
    private I18n:I18nService,
    private timezoneService:TimezoneService,
    private deviceService:DeviceService,
  ) { }

  ngOnInit():void {
    this.buildActors();
    this.buildTime();
  }

  isMobile():boolean {
    return this.deviceService.isMobile;
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
}
