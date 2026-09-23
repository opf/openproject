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

  it('asks for the dialog under a request id, so a pending one can be dropped', () => {
    const { service, request } = serviceReturning(resolved());

    openTimeEntryDialog(service, '/time_entries/1/dialog?onlyMe=true');

    expect(request).toHaveBeenCalledWith(
      '/time_entries/1/dialog?onlyMe=true',
      { method: 'GET' },
      false,
      'time-entry-dialog',
    );
  });

  it('names every dialog the same, so opening one replaces the one on its way', () => {
    const { service, request } = serviceReturning(resolved());

    openTimeEntryDialog(service, '/time_entries/1/dialog');
    openTimeEntryDialog(service, '/time_entries/dialog?date=2026-09-22');

    const [first, second] = request.mock.calls;
    expect(first[3]).toEqual(second[3]);
  });

  it('swallows the rejection an aborted request leaves behind', async () => {
    const abort = new DOMException('aborted', 'AbortError');
    const { service } = serviceReturning(Promise.reject(abort));

    expect(() => openTimeEntryDialog(service, '/time_entries/1/dialog')).not.toThrow();

    // Settle the microtask queue so an unhandled rejection would surface here.
    await Promise.resolve();
    await Promise.resolve();
  });
});
