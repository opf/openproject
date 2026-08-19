import { ChangeDetectionStrategy, Component, Input, OnInit, ViewEncapsulation, inject } from '@angular/core';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { Observable, timer } from 'rxjs';
import { distinctUntilChanged, map } from 'rxjs/operators';

@Component({
  selector: 'op-in-app-notification-relative-time',
  templateUrl: './in-app-notification-relative-time.component.html',
  styleUrls: ['./in-app-notification-relative-time.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class InAppNotificationRelativeTimeComponent implements OnInit {
  private I18n = inject(I18nService);
  private timezoneService = inject(TimezoneService);

  @Input() notification:INotification;
  @Input() hasActorByLine = true;

  // Fixed notification time
  fixedTime:string;

  // Format relative elapsed time (n seconds/minutes/hours ago)
  // at an interval for auto updating
  relativeTime$:Observable<string>;

  text = {
    updated_by_at: (age:string):string => this.I18n.t(
      'js.notifications.center.text_update_date_by',
      { date: age },
    ),
  };

  ngOnInit():void {
    this.buildTime();
  }

  private buildTime() {
    this.fixedTime = this.timezoneService.formattedDatetime(this.notification.createdAt);
    this.relativeTime$ = timer(0, 10000)
      .pipe(
        map(() => {
          const time = this.timezoneService.formattedRelativeDateTime(this.notification.createdAt);
          if (this.hasActorByLine && this.notification._links.actor) {
            return this.text.updated_by_at(time);
          }

          return `${time}.`;
        }),
        distinctUntilChanged(),
      );
  }
}
