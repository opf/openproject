// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

import { Injectable, Renderer2, RendererFactory2 } from '@angular/core';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Injectable({
  providedIn: 'root',
})

export class CopyToClipboardService {

  private renderer: Renderer2;

  constructor(
    readonly toastService:ToastService,
    readonly I18n:I18nService,
    readonly rendererFactory:RendererFactory2,
  ) {
    this.renderer = rendererFactory.createRenderer(null, null);
  }

  copy(content:string) {
    const supported = (document.queryCommandSupported && document.queryCommandSupported('copy'));
    const contentEl = this.appendContentEl(content);

    // At least select the input for the user
    // even when clipboard API not supported
    contentEl.select();
    contentEl.focus();
    if (supported) {
      try {
        // Copy it to the clipboard and remove the hidden input
        if (document.execCommand('copy')) {
          this.renderer.removeChild(document.body, contentEl);
          this.addNotification('addSuccess', this.I18n.t('js.clipboard.copied_successful'));
          return;
        }
      } catch (e) {
        console.log(
          `Your browser seems to support the clipboard API, but copying failed: ${e}`,
        );
      }
    }

    this.addNotification('addError', this.I18n.t('js.clipboard.browser_error'));
  }

  appendContentEl(value:string):JQuery<HTMLElement> {
    const contentEl = this.renderer.createElement('input');
    this.renderer.setAttribute(contentEl, 'value', value);
    this.renderer.appendChild(document.body, contentEl);
    return contentEl;
  }

  addNotification(type:'addSuccess'|'addError', message:string) {
    const notification = this.toastService[type](message);

    // Remove the notification some time later
    setTimeout(() => this.toastService.remove(notification), 5000);
  }
}
