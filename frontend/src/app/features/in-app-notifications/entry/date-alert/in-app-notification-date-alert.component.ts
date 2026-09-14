//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, HostBinding, Input, OnInit, ViewEncapsulation, inject } from '@angular/core';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IInAppNotificationDetailsAttribute, INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import moment, { Moment } from 'moment';

@Component({
  selector: 'op-in-app-notification-date-alert',
  templateUrl: './in-app-notification-date-alert.component.html',
  styleUrls: ['./in-app-notification-date-alert.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class InAppNotificationDateAlertComponent implements OnInit {
  private I18n = inject(I18nService);
  private timezoneService = inject(TimezoneService);

  @Input() aggregatedNotifications:INotification[];

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
    note: '', // date alerts do not have notes
  };

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

  private deriveDueDate(value:string, property:IInAppNotificationDetailsAttribute) {
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
    const first = dateAlerts[0];

    if (dateAlerts.length > 1) {
      const found = dateAlerts.find((notification) => notification._embedded.details[0].property === 'dueDate');
      return found || first;
    }

    // We only have one
    return first;
  }
}
