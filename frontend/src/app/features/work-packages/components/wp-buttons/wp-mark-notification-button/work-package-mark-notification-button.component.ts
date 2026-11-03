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

import { ChangeDetectionStrategy, Component, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HttpErrorResponse } from '@angular/common/http';

@Component({
  selector: 'op-work-package-mark-notification-button',
  templateUrl: './work-package-mark-notification-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageMarkNotificationButtonComponent {
  private I18n = inject(I18nService);
  private storeService = inject(WpSingleViewService);
  private toastService = inject(ToastService);

  @Input() public workPackage:WorkPackageResource;

  text = {
    mark_as_read: this.I18n.t('js.notifications.center.mark_as_read'),
    mark_as_unread: this.I18n.t('js.notifications.center.mark_as_unread'),
  };

  hasUnreadNotifications$ = this.storeService.hasNotifications$;

  markAllBelongingNotificationsAsRead():void {
    this.storeService.markAllAsRead();
    this.notifyActivityTab();
  }

  markAsUnread():void {
    this
      .storeService
      .markAsUnread(this.workPackage.id!)
      .subscribe({
        next: () => {
          document.dispatchEvent(new Event('ian-update-immediate'));
          this.notifyActivityTab();
        },
        error: (error:HttpErrorResponse) => this.toastService.addError(error),
      });
  }

  // emit custom event in order to inform the activity tab stimulus controller
  // will trigger an update of the activities list
  private notifyActivityTab():void {
    document.dispatchEvent(
      new CustomEvent('work-package-notifications-updated'),
    );
  }
}
