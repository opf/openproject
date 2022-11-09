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
  host: {
    class: 'op-ian-date-alert'
  }
})
export class InAppNotificationDateAlertComponent implements OnInit {
  @Input() aggregatedNotifications:INotification[];

  @Input() workPackage:WorkPackageResource;

  @HostBinding('class.op-ian-date-alert') className = true;

  @HostBinding('class.op-ian-date-alert_overdue') isOverdue:boolean;

  alertText:string;

  dateIsPast:boolean;

  propertyText:string;

  private daysDiff:string;

  text = {
    work_package_is: this.I18n.t('js.notifications.date_alerts.work_package_is'),
    overdue: this.I18n.t('js.notifications.date_alerts.overdue'),
    overdue_since: (difference_in_days:string):string =>
      this.I18n.t('js.notifications.date_alerts.overdue_since', { difference_in_days }),
    property_is: (difference_in_days:string):string =>
      this.I18n.t('js.notifications.date_alerts.property_is', { difference_in_days }),
    property_was: (difference_in_days:string):string =>
      this.I18n.t('js.notifications.date_alerts.property_was', { difference_in_days }),
    startDate: this.I18n.t('js.work_packages.properties.startDate'),
    dueDate: this.I18n.t('js.work_packages.properties.dueDate'),
    date: this.I18n.t('js.notifications.date_alerts.milestone_date'),
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
    const dateValue = this.timezoneService.parseISODate(detail.value);
    this.dateIsPast = dateValue.isBefore();
    this.isOverdue = this.dateIsPast && ['date', 'dueDate'].includes(property);
    this.daysDiff = this.dateDiff(dateValue);
    this.propertyText = this.isOverdue ? this.text.overdue : this.text[property];
    this.alertText = this.buildAlertText();
  }

  private buildAlertText():string {
    if (this.isOverdue) {
      return this.text.overdue_since(this.daysDiff);
    }

    if (this.dateIsPast) {
      return this.text.property_was(this.daysDiff);
    }

    return this.text.property_is(this.daysDiff);
  }

  private dateDiff(reference:Moment):string {
    const now = moment().startOf('day');
    const count = Math.abs(now.diff(reference, 'days'));

    return this.I18n.t('js.units.day', { count });
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
