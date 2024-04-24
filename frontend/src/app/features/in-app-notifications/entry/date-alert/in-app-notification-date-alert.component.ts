import {
  ChangeDetectionStrategy,
  Component,
  HostBinding,
  Input,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import * as moment from 'moment';
import { Moment } from 'moment';

@Component({
  selector: 'op-in-app-notification-date-alert',
  templateUrl: './in-app-notification-date-alert.component.html',
  styleUrls: ['./in-app-notification-date-alert.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class InAppNotificationDateAlertComponent implements OnInit {
  @Input() aggregatedNotifications:INotification[];

  @Input() workPackage:WorkPackageResource;

  @HostBinding('class.op-ian-date-alert') className = true;

  @HostBinding('class.op-ian-date-alert_overdue') isOverdue:boolean;

  alertText:string;

  dateIsPast:boolean;

  propertyText:string;

  text = {
    work_package_is: this.I18n.t('js.notifications.date_alerts.work_package_is'),
    overdue: this.I18n.t('js.notifications.date_alerts.overdue'),
    overdue_since: (difference_in_days:string):string =>
      this.I18n.t('js.notifications.date_alerts.overdue_since', { difference_in_days }),
    property_is: (difference_in_days:string):string =>
      this.I18n.t('js.notifications.date_alerts.property_is', { difference_in_days }),
    property_was: (difference_in_days:string):string =>
      this.I18n.t('js.notifications.date_alerts.property_was', { difference_in_days }),
    property_deleted: this.I18n.t('js.notifications.date_alerts.property_is_deleted'),
    startDate: this.I18n.t('js.work_packages.properties.startDate'),
    dueDate: this.I18n.t('js.work_packages.properties.dueDate'),
    date: this.I18n.t('js.notifications.date_alerts.milestone_date'),
    due_today: this.I18n.t('js.notifications.date_alerts.property_today'),
  };

  constructor(
    private I18n:I18nService,
    private timezoneService:TimezoneService,
  ) { }

  ngOnInit():void {
    // Find the most important date alert
    const interestingAlert = this.deriveMostRelevantAlert(this.aggregatedNotifications);

    const detail = interestingAlert._embedded.details[0];
    const property = detail.property;

    if (!detail.value) {
      this.propertyText = this.text[property];
      this.alertText = this.text.property_deleted;
    } else {
      this.deriveDueDate(detail.value, property);
    }
  }

  private deriveDueDate(value:string, property:'startDate'|'dueDate'|'date') {
    const dateValue = this.timezoneService.parseISODate(value).startOf('day');
    const today = moment();
    this.dateIsPast = dateValue.isBefore(today, 'day');
    this.isOverdue = this.dateIsPast && ['date', 'dueDate'].includes(property);
    const diff = this.dateDiff(dateValue);
    this.propertyText = (this.isOverdue && diff > 0) ? this.text.overdue : this.text[property];
    this.alertText = this.buildAlertText(diff);
  }

  private buildAlertText(daysDiff:number):string {
    if (daysDiff === 0) {
      return this.text.due_today;
    }

    const daysText = this.I18n.t('js.units.day', { count: daysDiff });
    if (this.isOverdue) {
      return this.text.overdue_since(daysText);
    }

    if (this.dateIsPast) {
      return this.text.property_was(daysText);
    }

    return this.text.property_is(daysText);
  }

  private dateDiff(reference:Moment):number {
    const now = moment().startOf('day');
    return Math.abs(now.diff(reference, 'days'));
  }

  private deriveMostRelevantAlert(aggregatedNotifications:INotification[]) {
    // Second case: We have one date alert + some others
    const dateAlerts = aggregatedNotifications.filter((notification) => notification.reason === 'dateAlert');
    const first = aggregatedNotifications[0];
    if (dateAlerts.length > 1) {
      const found = dateAlerts.find((notification) => notification._embedded.details[0].property === 'dueDate');
      return found || first;
    }

    // We only have one
    return first;
  }
}
