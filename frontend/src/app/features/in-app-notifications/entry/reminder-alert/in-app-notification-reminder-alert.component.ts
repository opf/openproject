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
