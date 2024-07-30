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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable } from '@angular/core';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Injectable({
  providedIn: 'root',
})

export class CopyToClipboardService {
  constructor(
    readonly toastService:ToastService,
    readonly I18n:I18nService,
  ) { }

  copy(content:string, successMessage?:string) {
    if (!navigator.clipboard) {
      // fallback for browsers that don't support clipboard API at all
      this.addNotification('addError', this.I18n.t('js.clipboard.browser_error', { content }));
    } else {
      void navigator.clipboard.writeText(content)
        .then(() => {
          this.addNotification('addSuccess', successMessage || this.I18n.t('js.clipboard.copied_successful'));
        })
        .catch(() => {
          // fallback when running into e.g. browser permission errors
          this.addNotification('addError', this.I18n.t('js.clipboard.browser_error', { content }));
        });
    }
  }

  addNotification(type:'addSuccess'|'addError', message:string) {
    const notification = this.toastService[type](message);

    // Remove the notification some time later
    if (notification) {
      setTimeout(() => this.toastService.remove(notification), 5000);
    }
  }
}
