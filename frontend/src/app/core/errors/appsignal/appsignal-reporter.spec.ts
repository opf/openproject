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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { HttpErrorResponse } from '@angular/common/http';
import { Span } from '@appsignal/javascript';
import type { MockInstance } from 'vitest';
import { Appsignal } from './appsignal-dependency';
import { AppsignalReporter } from './appsignal-reporter';

describe('AppsignalReporter', () => {
  let meta:HTMLMetaElement;
  let sendError:MockInstance<Appsignal['sendError']>;

  beforeEach(() => {
    meta = document.createElement('meta');
    meta.name = 'openproject_appsignal';
    document.head.appendChild(meta);
    // The network breadcrumb plugin replaces fetch and XMLHttpRequest globally.
    vi.spyOn(Appsignal.prototype, 'use').mockReturnValue(undefined);
    sendError = vi.spyOn(Appsignal.prototype, 'sendError').mockResolvedValue(new Span());
  });

  afterEach(() => {
    meta.remove();
    vi.restoreAllMocks();
  });

  async function loadedReporter() {
    const reporter = new AppsignalReporter();
    await reporter.loaded;
    return reporter;
  }

  async function tagsOfLastReport() {
    await vi.waitFor(() => expect(sendError).toHaveBeenCalled());
    const span = new Span();
    const setTags = vi.spyOn(span, 'setTags');
    const callback = sendError.mock.lastCall?.[1];
    if (typeof callback !== 'function') {
      throw new Error('Report was sent without a span callback');
    }

    callback(span);
    return setTags.mock.lastCall?.[0];
  }

  it('sends a captured HTTP error response as an Error', async () => {
    const reporter = await loadedReporter();
    const response = new HttpErrorResponse({ status: 500 });

    reporter.captureException(response);

    await vi.waitFor(() => expect(sendError).toHaveBeenCalledWith(expect.any(Error), expect.any(Function)));
    expect(sendError).toHaveBeenCalledWith(expect.objectContaining({ cause: response }), expect.any(Function));
  });

  it('tags the report with the context hooks before it is sent', async () => {
    const reporter = await loadedReporter();
    reporter.addHook(() => Promise.resolve({ user: 'admin' }));

    reporter.captureException(new Error('boom'));

    expect(await tagsOfLastReport()).toEqual(expect.objectContaining({ user: 'admin' }));
  });

  it('reports once with the other tags when a context hook fails', async () => {
    const reporter = await loadedReporter();
    reporter.addHook(() => Promise.reject(new Error('hook failed')), () => ({ project: 'demo' }));

    reporter.captureException(new Error('boom'));

    expect(await tagsOfLastReport()).toEqual(expect.objectContaining({ project: 'demo' }));
    expect(sendError).toHaveBeenCalledExactlyOnceWith(expect.objectContaining({ message: 'boom' }), expect.any(Function));
  });

  it('ignores errors until the client has loaded', () => {
    const reporter = new AppsignalReporter();

    reporter.captureException(new Error('early'));

    expect(sendError).not.toHaveBeenCalled();
    return reporter.loaded;
  });
});
