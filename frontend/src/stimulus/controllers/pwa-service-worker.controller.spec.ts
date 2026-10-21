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

import { vi } from 'vitest';
import { setupStimulusTest, type StimulusTestContext } from '../test-helpers';
import PwaServiceWorkerController from './pwa-service-worker.controller';

describe('PwaServiceWorkerController', () => {
  let ctx:StimulusTestContext;
  let register:ReturnType<typeof vi.fn>;

  async function mount() {
    ctx = await setupStimulusTest({ controllers: { 'pwa-service-worker': PwaServiceWorkerController } });
    await ctx.mount(`
      <div data-controller="pwa-service-worker"
           data-pwa-service-worker-url-value="/openproject/service-worker"
           data-pwa-service-worker-scope-value="/openproject/"></div>
    `);
  }

  beforeEach(() => {
    register = vi.fn().mockResolvedValue({});
    vi.stubGlobal('isSecureContext', true);
    Object.defineProperty(navigator, 'serviceWorker', { value: { register }, configurable: true });
  });

  afterEach(() => {
    ctx.dispose();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
    delete (navigator as { serviceWorker?:unknown }).serviceWorker;
  });

  it('registers the worker with the configured url and scope', async () => {
    await mount();

    expect(register).toHaveBeenCalledWith('/openproject/service-worker', { scope: '/openproject/' });
  });

  it('does nothing without service worker support', async () => {
    delete (navigator as { serviceWorker?:unknown }).serviceWorker;

    await mount();

    expect(register).not.toHaveBeenCalled();
  });

  it('does nothing outside a secure context', async () => {
    vi.stubGlobal('isSecureContext', false);

    await mount();

    expect(register).not.toHaveBeenCalled();
  });

  it('warns about a rejected registration', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const reason = new Error('SecurityError');
    register.mockRejectedValue(reason);

    await mount();
    await ctx.nextFrame();

    expect(warn).toHaveBeenCalledTimes(1);
    expect(warn).toHaveBeenCalledWith('Service worker registration failed', reason);
  });
});
