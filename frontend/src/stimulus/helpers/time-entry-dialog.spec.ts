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

import { vi } from 'vitest';
import type { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

import { openTimeEntryDialog } from './time-entry-dialog';

describe('openTimeEntryDialog', () => {
  function serviceReturning(result:Promise<{ html:string, headers:Headers }>) {
    const request = vi.fn().mockReturnValue(result);

    return { service: { request } as unknown as TurboRequestsService, request };
  }

  function resolved() {
    return Promise.resolve({ html: '', headers: new Headers() });
  }

  // The helper holds onto a request until it settles, so every test hands it back.
  async function settle() {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
  }

  function addDialog({ open, wrapped = true }:{ open:boolean, wrapped?:boolean }) {
    const dialog = document.createElement('dialog');
    dialog.id = 'time-entry-dialog';
    dialog.open = open;

    if (wrapped) {
      const helper = document.createElement('dialog-helper');
      helper.appendChild(dialog);
      document.body.appendChild(helper);
    } else {
      document.body.appendChild(dialog);
    }

    return dialog;
  }

  afterEach(async () => {
    await settle();
    document.querySelectorAll('#time-entry-dialog, dialog-helper').forEach((node) => node.remove());
  });

  it('asks for the dialog under a request id, so a pending one can be dropped', async () => {
    const { service, request } = serviceReturning(resolved());

    openTimeEntryDialog(service, '/time_entries/1/dialog?onlyMe=true');

    expect(request).toHaveBeenCalledWith(
      '/time_entries/1/dialog?onlyMe=true',
      { method: 'GET' },
      false,
      'time-entry-dialog',
    );
    await settle();
  });

  // Aborting cannot take back a response that already arrived, and it would render over the
  // dialog the first click is still busy putting up.
  it('turns away a second request while the first is outstanding', async () => {
    const { service, request } = serviceReturning(resolved());

    openTimeEntryDialog(service, '/time_entries/1/dialog');
    openTimeEntryDialog(service, '/time_entries/2/dialog');

    expect(request).toHaveBeenCalledTimes(1);
    await settle();
  });

  it('turns away a request while the dialog is on screen', () => {
    addDialog({ open: true });
    const { service, request } = serviceReturning(resolved());

    openTimeEntryDialog(service, '/time_entries/1/dialog');

    expect(request).not.toHaveBeenCalled();
  });

  it('asks again once the previous request is done and no dialog is up', async () => {
    const { service, request } = serviceReturning(resolved());

    openTimeEntryDialog(service, '/time_entries/1/dialog');
    await settle();
    openTimeEntryDialog(service, '/time_entries/2/dialog');

    expect(request).toHaveBeenCalledTimes(2);
    await settle();
  });

  // Otherwise the dialog stream morphs the leftover instead of rendering a fresh one, and the
  // Angular backed fields do not come back.
  it('drops a closed dialog left behind by the previous open', async () => {
    addDialog({ open: false });
    const { service } = serviceReturning(resolved());

    openTimeEntryDialog(service, '/time_entries/1/dialog');

    expect(document.querySelector('#time-entry-dialog')).toBeNull();
    expect(document.querySelector('dialog-helper')).toBeNull();
    await settle();
  });

  it('drops a closed dialog that was appended without its helper', async () => {
    addDialog({ open: false, wrapped: false });
    const { service } = serviceReturning(resolved());

    openTimeEntryDialog(service, '/time_entries/1/dialog');

    expect(document.querySelector('#time-entry-dialog')).toBeNull();
    await settle();
  });

  it('swallows the rejection an aborted request leaves behind', async () => {
    const abort = new DOMException('aborted', 'AbortError');
    const { service } = serviceReturning(Promise.reject(abort));

    expect(() => openTimeEntryDialog(service, '/time_entries/1/dialog')).not.toThrow();

    // Settle the microtask queue so an unhandled rejection would surface here.
    await settle();
  });
});
