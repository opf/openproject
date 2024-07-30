/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';

export default class OAuthAccessGrantNudgeModalController extends Controller<HTMLDialogElement> {
  static targets = [
    'requestAccessForm',
    'requestAccessButton',
    'header',
    'loadingIndicator',
    'requestAccessBody',
    'closeButton',
  ];

  static values = {
    closeButtonLabel: String,
    loadingScreenReaderMessage: String,
  };

  declare readonly requestAccessFormTarget:HTMLFormElement;
  declare readonly requestAccessBodyTarget:HTMLElement;
  declare readonly headerTarget:HTMLElement;
  declare readonly loadingIndicatorTarget:HTMLElement;
  declare readonly requestAccessButtonTarget:HTMLElement;
  declare readonly closeButtonTarget:HTMLElement;
  declare readonly hasRequestAccessButtonTarget:boolean;

  declare readonly closeButtonLabelValue:string;
  declare readonly loadingScreenReaderMessageValue:string;

  connect() {
    this.element.showModal();

    if (this.hasRequestAccessButtonTarget) {
      // Focus on the request access button
      this.requestAccessButtonTarget.focus();
    }
  }

  public requestAccess(evt:Event):void {
    evt.preventDefault();

    this.activateLoadingState();
    // NOTE: Automated requestAccessFormTarget.requestSubmit() is not possible due to CSP restrictions
    // See: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/form-action
    window.location.href = this.requestAccessFormTarget.action;
  }

  // Hide the request access button and show the loading indicator
  private activateLoadingState() {
    this.requestAccessButtonTarget.classList.add('d-none');

    // Set the close button label to "Cancel"
    this.closeButtonTarget.textContent = this.closeButtonLabelValue;

    // Convey to screen readers that we're waiting for the request
    this.headerTarget.classList.add('sr-only');
    this.headerTarget.textContent = this.loadingScreenReaderMessageValue;

    // Hide the request access body and show the loading indicator
    this.requestAccessBodyTarget.classList.add('d-none');
    this.loadingIndicatorTarget.classList.remove('d-none');
  }
}
