import { ChangeDetectionStrategy, Component, HostBinding, Input, OnInit, ViewEncapsulation, inject } from '@angular/core';
import { DeviceService } from 'core-app/core/browser/device.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';

@Component({
  selector: 'op-in-app-notification-actors-line',
  templateUrl: './in-app-notification-actors-line.component.html',
  styleUrls: ['./in-app-notification-actors-line.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class InAppNotificationActorsLineComponent implements OnInit {
  readonly deviceService = inject(DeviceService);
  private I18n = inject(I18nService);

  @HostBinding('class.op-ian-actors') className = true;

  @Input() aggregatedNotifications:INotification[];

  @Input() notification:INotification;

  // The actor, if any
  actors:PrincipalLike[] = [];

  text = {
    and: this.I18n.t('js.notifications.center.label_actor_and'),
    and_other_singular: this.I18n.t('js.notifications.center.and_more_users.one'),
    and_other_plural: (count:number):string => this.I18n.t(
      'js.notifications.center.and_more_users.other',
      { count },
    ),
    loading: this.I18n.t('js.ajax.loading'),
    placeholder: this.I18n.t('js.placeholders.default'),
    mark_as_read: this.I18n.t('js.notifications.center.mark_as_read'),
  };

  ngOnInit():void {
    // Don't show the actor if the first item is actor-less (date alert)
    if (this.notification._links.actor) {
      this.buildActors();
    }
  }

  text_for_additional_authors(number:number):string {
    if (number === 1) {
      return this.text.and_other_singular;
    }

    return this.text.and_other_plural(number);
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
