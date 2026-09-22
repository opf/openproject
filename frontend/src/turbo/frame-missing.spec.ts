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

import { environment } from '../environments/environment';
import { addFrameMissingListener } from './frame-missing';

describe('addFrameMissingListener', () => {
  const originalHref = window.location.href;
  const originalProduction = environment.production;
  let controller:AbortController;
  let frame:HTMLElement;
  let visit:ReturnType<typeof vi.fn>;

  beforeEach(() => {
    environment.production = false;
    controller = new AbortController();
    addFrameMissingListener(document, controller.signal);

    frame = document.createElement('turbo-frame');
    frame.id = 'probe';
    frame.setAttribute('disabled', '');
    document.body.appendChild(frame);

    visit = vi.fn().mockResolvedValue(undefined);
    vi.spyOn(console, 'warn').mockImplementation(() => undefined);
  });

  afterEach(() => {
    environment.production = originalProduction;
    controller.abort();
    frame.remove();
    window.history.replaceState(window.history.state, '', originalHref);
    vi.restoreAllMocks();
  });

  function responseFrom(url:string, status = 200) {
    const response = new Response('<html><body></body></html>', {
      status,
      headers: { 'Content-Type': 'text/html' },
    });
    Object.defineProperty(response, 'url', { value: url });
    return response;
  }

  function dispatchFrameMissing(response:Response) {
    const event = new CustomEvent('turbo:frame-missing', {
      bubbles: true,
      cancelable: true,
      detail: { response, visit },
    });
    frame.dispatchEvent(event);
    return event;
  }

  const otherUrl = () => new URL('/projects/new', window.location.origin).href;
  const currentUrlWithoutHash = () => window.location.href.split('#')[0];

  it('visits the response itself when it comes from another URL', () => {
    const response = responseFrom(otherUrl());

    const event = dispatchFrameMissing(response);

    expect(event.defaultPrevented).toBe(true);
    expect(visit).toHaveBeenCalledTimes(1);
    expect(visit).toHaveBeenCalledWith(response, {});
  });

  it('leaves a response from the current URL to Turbo', () => {
    const event = dispatchFrameMissing(responseFrom(currentUrlWithoutHash()));

    expect(event.defaultPrevented).toBe(false);
    expect(visit).not.toHaveBeenCalled();
  });

  it('ignores the fragment when comparing with the current URL', () => {
    window.history.replaceState(window.history.state, '', '#section');

    const event = dispatchFrameMissing(responseFrom(currentUrlWithoutHash()));

    expect(event.defaultPrevented).toBe(false);
    expect(visit).not.toHaveBeenCalled();
  });

  it('leaves unsuccessful responses to Turbo', () => {
    const event = dispatchFrameMissing(responseFrom(otherUrl(), 500));

    expect(event.defaultPrevented).toBe(false);
    expect(visit).not.toHaveBeenCalled();
    expect(console.warn).not.toHaveBeenCalled();
  });

  it('warns about the implicit navigation when debugging', () => {
    dispatchFrameMissing(responseFrom(otherUrl()));

    expect(console.warn).toHaveBeenCalledWith(expect.stringContaining('turbo-frame#probe'));
    expect(console.warn).toHaveBeenCalledWith(expect.stringContaining('data-turbo-frame="_top"'));
  });
});
