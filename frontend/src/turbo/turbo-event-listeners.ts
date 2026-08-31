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

import { readScriptNonce, scrubScriptElements } from './csp-script-nonce';
import { DialogCloseDetail } from './dialog-stream-action';

export function addTurboEventListeners(doc:Document = document, signal?:AbortSignal) {
  // Close the primer dialog when the form inside has been submitted with a success response.
  //
  // If you want to keep the dialog open even after a successful form submission, you can add the
  // `data-keep-open-on-submit="true"` attribute to the dialog element.
  //
  // It is necessary to close the primer dialog using the `close()` method, otherwise
  // it will leave an overflow:hidden attribute on the body, which prevents scrolling on the page.
  //
  // Also, we will dispatch a custom `dialog:close` event when the dialog is closed.
  doc.addEventListener('turbo:submit-end', (event) => {
    const { detail: { success }, target } = event;

    if (success && target instanceof HTMLFormElement) {
      const dialog = target.closest('dialog')!;

      if (dialog) {
        if (dialog.dataset.keepOpenOnSubmit !== 'true') {
          dialog.close('close-event-already-dispatched');
          doc.dispatchEvent(new CustomEvent<DialogCloseDetail>('dialog:close', { detail: { dialog, submitted: true } }));
        }
      }
    }
  }, { signal });

  // Append turbo nonce for drive requests
  doc.addEventListener('turbo:before-fetch-request', (event) => {
    // Turbo Drive does not send a referrer like turbolinks used to, so let's simulate it here
    const { headers } = event.detail.fetchOptions;
    headers['Turbo-Referrer'] = window.location.href;
    headers['X-Turbo-Nonce'] = readScriptNonce();
  }, { signal });

  // Scrub mismatched-nonce scripts from a Turbo Drive page load (full reload)
  doc.addEventListener('turbo:before-render', (event) => {
    scrubScriptElements(event.detail.newBody);
  }, { capture: true, signal });

  // Scrub mismatched-nonce scripts from a Turbo Stream (partial update)
  doc.addEventListener('turbo:before-stream-render', (event) => {
    const fallbackToDefaultActions = event.detail.render;

    event.detail.render = async (streamElement) => {
      const content = streamElement.templateElement.content;
      scrubScriptElements(content);

      const result = await fallbackToDefaultActions(streamElement);
      doc.dispatchEvent(new CustomEvent('op:turbo-stream-rendered'));
      return result;
    };
  }, { signal });

  // Scrub mismatched-nonce scripts from a Turbo Frame render
  doc.addEventListener('turbo:before-frame-render', (event) => {
    scrubScriptElements(event.detail.newFrame);
  }, { capture: true, signal });
}
