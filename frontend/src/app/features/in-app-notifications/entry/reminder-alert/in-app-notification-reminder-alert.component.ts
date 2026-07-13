import { ChangeDetectionStrategy, Component, HostBinding, Input, OnInit, ViewEncapsulation, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IInAppNotificationDetailsResource, INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';

@Component({
  selector: 'op-in-app-notification-reminder-alert',
  templateUrl: './in-app-notification-reminder-alert.component.html',
  styleUrls: ['./in-app-notification-reminder-alert.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class InAppNotificationReminderAlertComponent implements OnInit {
  private I18n = inject(I18nService);

  @Input() aggregatedNotifications:INotification[];

  @HostBinding('class.op-ian-reminder-alert') className = true;

  reminderNote:string;
  reminderAlert:INotification;
  hasDateAlert = false;
  dateAlerts:INotification[] = [];

  ngOnInit():void {
    this.reminderAlert = this.deriveMostRecentReminder(this.aggregatedNotifications);
    this.reminderNote = this.extractReminderNoteValue(this.reminderAlert._embedded.details);
    this.dateAlerts = this.aggregatedNotifications.filter((notification) => notification.reason === 'dateAlert');
    this.hasDateAlert = this.dateAlerts.length > 0;
  }

  private deriveMostRecentReminder(aggregatedNotifications:INotification[]):INotification {
    const reminderAlerts = aggregatedNotifications.filter((notification:INotification) => notification.reason === 'reminder');

    if (reminderAlerts.length > 1) {
      const mostRecent = reminderAlerts.reduce((prev:INotification, current:INotification) => {
        const prevDate = new Date(prev.createdAt);
        const currentDate = new Date(current.createdAt);
        return prevDate > currentDate ? prev : current;
      });
      return mostRecent;
    }

    return reminderAlerts[0];
  }

  private extractReminderNoteValue(details:IInAppNotificationDetailsResource[]):string {
    const noteDetail = details.find((detail:IInAppNotificationDetailsResource) => detail.property === 'note');
    if (noteDetail?.value) {
      return this.I18n.t('js.notifications.reminders.note', { note: (noteDetail?.value) });
    }

    return '';
  }
}
