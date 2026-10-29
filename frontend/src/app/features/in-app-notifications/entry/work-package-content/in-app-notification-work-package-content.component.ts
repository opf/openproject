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
import { DeviceService } from 'core-app/core/browser/device.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { hasNotificationReason } from 'core-app/features/in-app-notifications/entry/has-notification-reason';

@Component({
  selector: 'op-in-app-notification-work-package-content',
  templateUrl: './in-app-notification-work-package-content.component.html',
  styleUrls: ['./in-app-notification-work-package-content.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class InAppNotificationWorkPackageContentComponent implements OnInit {
  readonly pathHelper = inject(PathHelperService);
  readonly deviceService = inject(DeviceService);

  @HostBinding('class.op-ian-work-package-content') className = true;

  @Input() workPackage:WorkPackageResource;

  @Input() notification:INotification;

  @Input() aggregatedNotifications:INotification[];

  hasReminderAlert = false;

  showDateAlert = false;

  ngOnInit():void {
    this.hasReminderAlert = hasNotificationReason(this.aggregatedNotifications, 'reminder');
    this.showDateAlert = hasNotificationReason(this.aggregatedNotifications, 'dateAlert');
  }

  isMobile():boolean {
    return this.deviceService.isMobile;
  }

  onLinkClick(event:Event):void {
    event.stopPropagation();
  }

  typeHighlightingClass(workPackage:WorkPackageResource):string {
    return Highlighting.typeClass(workPackage.type.id!);
  }
}
