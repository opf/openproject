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

import type { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

// Every my time tracking view opens the one dialog with this id. Asking for it twice before
// the first response lands renders the dialog stream twice, and the second render morphs the
// contents of the dialog already on screen, which its Angular backed fields do not survive:
// the work package, activity and date inputs come back as bare labels. Naming the request
// lets the service abort the one still in flight, so only the last click renders.
const DIALOG_REQUEST_ID = 'time-entry-dialog';

export function openTimeEntryDialog(turboRequests:TurboRequestsService, url:string):void {
  turboRequests
    .request(url, { method: 'GET' }, false, DIALOG_REQUEST_ID)
    // The service reports what went wrong itself and rethrows; an abort is this helper
    // replacing the request and is not a failure at all.
    .catch(() => undefined);
}
