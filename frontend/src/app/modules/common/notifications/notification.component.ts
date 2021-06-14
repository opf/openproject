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

import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import {
  INotification,
  NotificationsService,
  NotificationType
} from 'core-app/modules/common/notifications/notifications.service';

@Component({
  templateUrl: './notification.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'notification'
})
export class NotificationComponent implements OnInit {
  @Input() public notification:INotification;

  public text = {
    close_popup: this.I18n.t('js.close_popup_title'),
  };

  public type:NotificationType;
  public uploadCount = 0;
  public show = false;

  constructor(readonly I18n:I18nService,
              readonly notificationsService:NotificationsService) {
  }

  ngOnInit() {
    this.type = this.notification.type;
  }

  public get data() {
    return this.notification.data;
  }

  public canBeHidden() {
    return this.data && this.data.length > 5;
  }

  public removable() {
    return this.notification.type !== 'upload';
  }

  public remove() {
    this.notificationsService.remove(this.notification);
  }

  /**
   * Execute the link callback from content.link.target
   * and close this notification.
   */
  public executeTarget() {
    if (this.notification.link) {
      this.notification.link.target();
      this.remove();
    }
  }

  public onUploadError(message:string) {
    this.remove();
  }

  public onUploadSuccess() {
    this.uploadCount += 1;
  }

  public get uploadText() {
    return this.I18n.t('js.label_upload_counter',
      { done: this.uploadCount, count: this.data.length });
  }
}
