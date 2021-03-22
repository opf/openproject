//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { INotification, NotificationsService } from 'core-app/modules/common/notifications/notifications.service';
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";

export const notificationsContainerSelector = 'notifications-container';

@Component({
  template: `
    <div class="notification-box--wrapper">
      <div class="notification-box--casing">
        <notification [notification]="notification" *ngFor="let notification of stack"></notification>
      </div>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: notificationsContainerSelector
})
export class NotificationsContainerComponent extends UntilDestroyedMixin implements OnInit {

  public stack:INotification[] = [];

  constructor(readonly notificationsService:NotificationsService,
              readonly cdRef:ChangeDetectorRef) {
    super();
  }

  ngOnInit():void {
    this.notificationsService
      .current
      .values$('Subscribing to changes in the notification stack')
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(stack => {
        this.stack = stack;
        this.cdRef.detectChanges();
      });
  }
}


