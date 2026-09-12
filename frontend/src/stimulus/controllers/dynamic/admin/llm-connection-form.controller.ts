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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';

// Saving the connection contacts the LLM server, which can take seconds. This
// gives the administrator feedback while that happens, and keeps the typed API
// key out of Turbo's page cache.
export default class extends Controller {
  static targets = ['submitButton', 'progressBanner', 'secretInput'];

  declare readonly submitButtonTargets:HTMLButtonElement[];
  declare readonly progressBannerTarget:HTMLElement;
  declare readonly secretInputTargets:HTMLInputElement[];

  connect():void {
    this.element.addEventListener('submit', this.showProgress);
    document.addEventListener('turbo:before-cache', this.clearSecrets);
  }

  disconnect():void {
    this.element.removeEventListener('submit', this.showProgress);
    document.removeEventListener('turbo:before-cache', this.clearSecrets);
  }

  // Turbo caches the rendered page for the back button. Without this the typed
  // API key would be restored into the DOM on navigating back.
  private clearSecrets = ():void => {
    this.secretInputTargets.forEach((input:HTMLInputElement) => {
      input.value = '';
    });
  };

  private showProgress = ():void => {
    this.progressBannerTarget.hidden = false;

    // aria-disabled rather than disabled: disabling a button while it holds
    // focus moves focus to <body>, silently dropping keyboard users to the top
    // of the page. It also keeps the button in the submitted form data.
    this.submitButtonTargets.forEach((button:HTMLButtonElement) => {
      button.setAttribute('aria-disabled', 'true');
    });
  };
}
