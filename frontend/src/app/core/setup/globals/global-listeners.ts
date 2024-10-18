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
import { openExternalLinksInNewTab, performAnchorHijacking } from './global-listeners/link-hijacking';

/**
 * A set of listeners that are relevant on every page to set sensible defaults
 */
export function initializeGlobalListeners():void {
  document
    .documentElement
    .addEventListener('click', (evt:MouseEvent) => {
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

      const callbacks = [
        openExternalLinksInNewTab,
        performAnchorHijacking,
      ];

      // eslint-disable-next-line no-restricted-syntax
      for (const fn of callbacks) {
        if (fn.call(linkElement, evt, linkElement)) {
          evt.preventDefault();
          break;
        }
      }

      // Prevent angular handling clicks on href="#..." links from other libraries
      // (especially jquery-ui and its datepicker) from routing to <base url>/#
      performAnchorHijacking(evt, linkElement);
    });

  // Jump to the element given by location.hash, if present
  const { hash } = window.location;
  if (hash && hash.startsWith('#')) {
    try {
      const el = document.querySelector(hash);
      el && el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    } catch (e) {
      // This is very likely an invalid selector such as a Google Analytics tag.
      // We can safely ignore this and just not scroll in this case.
      // Still log the error so one can confirm the reason there is no scrolling.
      console.log(`Could not scroll to given location hash: ${hash} ( ${e.message})`);
    }
  }

  // Global submitting hook,
  // necessary to avoid a data loss warning on beforeunload
  jQuery(document).on('submit', 'form', () => {
    window.OpenProject.pageIsSubmitted = true;
  });

  // Global beforeunload hook
  jQuery(window).on('beforeunload', (e:JQuery.TriggeredEvent) => {
    const event = e.originalEvent as BeforeUnloadEvent;
    if (window.OpenProject.pageWasEdited && !window.OpenProject.pageIsSubmitted) {
      // Cancel the event
      event.preventDefault();
      // Chrome requires returnValue to be set
      event.returnValue = I18n.t('js.work_packages.confirm_edit_cancel');
    }
  });

  // Disable global drag & drop handling, which results in the browser loading the image and losing the page
  jQuery(document.documentElement)
    .on('dragover drop', (evt:Event) => {
      evt.preventDefault();
      return false;
    });

  // Bootstrap legacy app code
  setupServerResponse();
}
