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

import type { FetchResponse } from '@rails/request.js';

import { withLoadingIndicator } from './request-helpers';

describe('withLoadingIndicator', () => {
  let indicator:HTMLElement|null;

  function addIndicator() {
    const element = document.createElement('div');
    element.id = 'global-loading-indicator';
    element.hidden = true;
    document.body.appendChild(element);
    indicator = element;
    return element;
  }

  afterEach(() => {
    indicator?.remove();
    indicator = null;
  });

  it('shows the indicator while the request is pending and hides it on success', async () => {
    const element = addIndicator();
    let resolveRequest!:(response:FetchResponse) => void;
    const request = new Promise<FetchResponse>((resolve) => { resolveRequest = resolve; });

    const wrapped = withLoadingIndicator(request);
    expect(element).toBeVisible();

    resolveRequest({} as FetchResponse);
    await wrapped;

    expect(element).not.toBeVisible();
  });

  it('hides the indicator when the request rejects and propagates the rejection', async () => {
    const element = addIndicator();
    const error = new Error('boom');

    const wrapped = withLoadingIndicator(Promise.reject(error));

    await expect(wrapped).rejects.toBe(error);
    expect(element).not.toBeVisible();
  });

  it('throws when the loading indicator is absent', () => {
    expect(() => withLoadingIndicator(Promise.resolve({} as FetchResponse))).toThrow();
  });
});
