// -- copyright
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IanCenterService } from '../state/ian-center.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';

@Component({
  templateUrl: './empty-state.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['./empty-state.component.sass'],
  selector: 'op-empty-state',
})
export class EmptyStateComponent {
  image = {
    no_notification: imagePath('notification-center/empty-state-no-notification.svg'),
    no_selection: imagePath('notification-center/empty-state-no-selection.svg'),
    loading: imagePath('notification-center/notification_loading.gif'),
  };

  text = {
    no_notification: this.I18n.t('js.notifications.center.empty_state.no_notification'),
    no_selection: this.I18n.t('js.notifications.center.empty_state.no_selection'),
  };

  hasNotifications$ = this.storeService.hasNotifications$;

  loading$ = this.storeService.query.selectLoading();

  constructor(
    readonly I18n:I18nService,
    readonly storeService:IanCenterService,
  ) {
  }
}
