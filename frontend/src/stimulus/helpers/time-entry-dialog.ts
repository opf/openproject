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

import type { FrameElement } from '@hotwired/turbo';
import type { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

// Every my time tracking view opens the one dialog with this id, and asking for it a second
// time renders the dialog stream over the first: the second render morphs the contents of the
// dialog on screen, which its Angular backed fields do not survive, and the work package,
// activity and date inputs come back as bare labels.
const DIALOG_ID = 'time-entry-dialog';

// Aborting only helps while a request is still on the wire. A response that has already
// arrived renders no matter what, and until it has put the modal up there is nothing over the
// view to stop the next click, so a second request is turned away rather than raced.
let awaitingDialog = false;

function timeEntryDialog():HTMLDialogElement|null {
  const dialog = document.getElementById(DIALOG_ID);

  return dialog instanceof HTMLDialogElement ? dialog : null;
}

// A closed dialog is meant to be taken out of the document by the dialog stream action, but
// one is left behind often enough that the next open finds it and morphs it instead of
// rendering afresh. Dropping it first means the next open builds its fields from scratch.
function discardClosedDialog():void {
  const dialog = timeEntryDialog();

  if (dialog && !dialog.open) {
    const helper = dialog.parentElement;

    (helper?.tagName === 'DIALOG-HELPER' ? helper : dialog).remove();
  }
}

export function openTimeEntryDialog(turboRequests:TurboRequestsService, url:string):void {
  if (awaitingDialog || timeEntryDialog()?.open) {
    return;
  }

  discardClosedDialog();
  awaitingDialog = true;

  turboRequests
    .request(url, { method: 'GET' }, false, DIALOG_ID)
    // The service reports what went wrong itself and rethrows.
    .catch(() => undefined)
    .finally(() => { awaitingDialog = false; });
}

export function reloadTimeTrackingView(element:Element):void {
  const frame = element.closest<FrameElement>('turbo-frame');

  if (!frame) {
    window.location.reload();
  } else if (frame.getAttribute('src')) {
    void frame.reload();
  } else {
    // Setting the frame-src for the first time refreshes it
    frame.setAttribute('src', window.location.href);
  }
}
