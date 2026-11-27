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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, HostBinding, Input, OnInit, ViewEncapsulation, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { notificationResourceId } from 'core-app/features/in-app-notifications/notification-resource-id';

@Component({
  selector: 'op-in-app-notification-document-content',
  templateUrl: './in-app-notification-document-content.component.html',
  styleUrls: ['./in-app-notification-document-content.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class InAppNotificationDocumentContentComponent implements OnInit {
  private I18n = inject(I18nService);
  private pathHelper = inject(PathHelperService);

  @HostBinding('class.op-ian-document-content') className = true;

  @Input() notification:INotification;

  @Input() aggregatedNotifications:INotification[];

  documentPath:string;

  text = {
    document: this.I18n.t('js.label_document'),
  };

  ngOnInit():void {
    this.documentPath = this.pathHelper.documentPath(notificationResourceId(this.notification, 'documents')!);
  }

  onLinkClick(event:Event):void {
    event.stopPropagation();
  }
}
