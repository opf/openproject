//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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


import {Component, ElementRef, OnInit} from "@angular/core";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {ConfigurationService} from "core-app/modules/common/config/configuration.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

export const copyToClipboardSelector = 'copy-to-clipboard';

@Component({
  template: '',
  selector: copyToClipboardSelector
})
export class CopyToClipboardDirective implements OnInit {
  public clickTarget:string;
  public clipboardTarget:string;
  private target:JQuery;

  constructor(readonly NotificationsService:NotificationsService,
              readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly ConfigurationService:ConfigurationService) {
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    // Get inputs as attributes since this is a bootstrapped directive
    this.clickTarget = element.getAttribute('click-target');
    this.clipboardTarget = element.getAttribute('clipboard-target');

    jQuery(this.clickTarget).on('click', (evt:JQuery.TriggeredEvent) => this.onClick(evt));

    element.classList.add('copy-to-clipboard');
    this.target = jQuery(this.clipboardTarget ? this.clipboardTarget : element);
  }

  addNotification(type:'addSuccess'|'addError', message:string) {
    let notification = this.NotificationsService[type](message);

    // Remove the notification some time later
    setTimeout(() => this.NotificationsService.remove(notification), 5000);
  }

  onClick($event:JQuery.TriggeredEvent) {
    var supported = (document.queryCommandSupported && document.queryCommandSupported('copy'));
    $event.preventDefault();

    // At least select the input for the user
    // even when clipboard API not supported
    this.target.select().focus();

    if (supported) {
      try {
        // Copy it to the clipboard
        if (document.execCommand('copy')) {
          this.addNotification('addSuccess', this.I18n.t('js.clipboard.copied_successful'));
          return;
        }
      } catch (e) {
        console.log(
          'Your browser seems to support the clipboard API, but copying failed: ' + e
        );
      }
    }

    this.addNotification('addError', this.I18n.t('js.clipboard.browser_error'));
  }
}


