// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Component, Inject, Input, OnInit} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {
  INotification,
  NotificationsService,
  NotificationType
} from 'core-components/common/notifications/notifications.service';

@Component({
  template: require('!!raw-loader!./notification.component.html'),
  selector: 'notification'
})
export class NotificationComponent implements OnInit {
  @Input() public notification:INotification;

  public text = {
    close_popup: this.I18n.t('js.close_popup_title'),
  }

  public type:NotificationType;
  public uploadCount = 0;
  public show = false;

  constructor(@Inject(I18nToken) readonly I18n:op.I18n,
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
    if (this.removable()) {
      this.notificationsService.remove(this.notification);
    }
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

  public onUploadError() {
    // Override the current type
    this.type = 'error';
  }

  public onUploadSuccess() {
    this.uploadCount += 1;
  }

  public get uploadText() {
    return this.I18n.t('js.label_upload_counter',
      { done: this.uploadCount, count: this.data.length});
  }
}
