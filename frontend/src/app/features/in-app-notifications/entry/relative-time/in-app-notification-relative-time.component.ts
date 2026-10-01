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
