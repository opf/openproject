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

import { setupServerResponse } from 'core-app/core/setup/globals/global-listeners/setup-server-response';
import { performAnchorHijacking } from './global-listeners/link-hijacking';

/**
 * A set of listeners that are relevant on every page to set sensible defaults
 */
export function initializeGlobalListeners():void {
  document
    .documentElement
    .addEventListener('click', (evt) => {
      const target = evt.target as HTMLElement;

      // Avoid defaulting clicks on elements already removed from DOM
      if (!document.contains(target)) {
        evt.preventDefault();
        return;
      }

      // Avoid handling clicks on anything other than a
      const linkElement = target.closest<HTMLAnchorElement>('a');
      if (!linkElement) {
        return;
      }

      // Avoid opening new tab when clicking links while editing in ckeditor
      if (linkElement.classList.contains('ck-link_selected')) {
        evt.preventDefault();
        return;
      }

      // Prevent angular handling clicks on href="#..." links from other libraries
      // from routing to <base url>/#
      if (performAnchorHijacking(evt, linkElement)) {
        evt.preventDefault();
      }
    });

  // Listen for 'zenModeToggled' event to toggle Zen Mode styling on the body.
  // Adds 'zen-mode' class if active; removes it if not.
  window.addEventListener('zenModeToggled', (event:CustomEvent) => {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-argument
    document.body.classList.toggle('zen-mode', event.detail.active);
  });

  // Disable global drag & drop handling, which results in the browser loading the image and losing the page
  const disableDragDefaults = (evt:Event) => { evt.preventDefault(); };
  document.documentElement.addEventListener('dragover', disableDragDefaults);
  document.documentElement.addEventListener('drop', disableDragDefaults);

  // Bootstrap legacy app code
  setupServerResponse();
}
