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
import { setupStimulusTest, type StimulusTestContext } from '../test-helpers';
import PwaServiceWorkerController from './pwa-service-worker.controller';

describe('PwaServiceWorkerController', () => {
  let ctx:StimulusTestContext;
  let register:ReturnType<typeof vi.fn>;

  async function mount(signedIn:'true'|'false'|null = 'true') {
    const signedInAttribute = signedIn === null ? '' : `data-pwa-service-worker-signed-in-value="${signedIn}"`;
    ctx = await setupStimulusTest({ controllers: { 'pwa-service-worker': PwaServiceWorkerController } });
    await ctx.mount(`
      <div data-controller="pwa-service-worker"
           data-pwa-service-worker-url-value="/openproject/service-worker"
           data-pwa-service-worker-scope-value="/openproject/"
           ${signedInAttribute}></div>
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

  it('swallows a rejected registration', async () => {
    const unhandled = vi.fn();
    window.addEventListener('unhandledrejection', unhandled);
    register.mockRejectedValue(new Error('SecurityError'));

    await mount();
    await ctx.nextFrame();

    expect(register).toHaveBeenCalled();
    expect(unhandled).not.toHaveBeenCalled();
    window.removeEventListener('unhandledrejection', unhandled);
  });

  it('swallows a synchronous registration error', async () => {
    register.mockImplementation(() => { throw new Error('boom'); });

    await mount();

    expect(register).toHaveBeenCalled();
  });

  describe('shell caches', () => {
    let keys:ReturnType<typeof vi.fn>;
    let deleteCache:ReturnType<typeof vi.fn>;

    beforeEach(() => {
      keys = vi.fn().mockResolvedValue(['openproject-shell-abc', 'some-other-cache', 'openproject-shell-def']);
      deleteCache = vi.fn().mockResolvedValue(true);
      vi.stubGlobal('caches', { keys, delete: deleteCache });
    });

    it('deletes only the shell caches when signed out', async () => {
      await mount('false');
      await ctx.nextFrame();

      expect(deleteCache).toHaveBeenCalledTimes(2);
      expect(deleteCache).toHaveBeenCalledWith('openproject-shell-abc');
      expect(deleteCache).toHaveBeenCalledWith('openproject-shell-def');
    });

    it('keeps the caches when signed in', async () => {
      await mount('true');
      await ctx.nextFrame();

      expect(deleteCache).not.toHaveBeenCalled();
    });

    it('keeps the caches when the signed in state is missing', async () => {
      await mount(null);
      await ctx.nextFrame();

      expect(deleteCache).not.toHaveBeenCalled();
    });

    it('still registers the worker when signed out', async () => {
      await mount('false');

      expect(register).toHaveBeenCalled();
    });

    it('does nothing without Cache Storage support', async () => {
      delete (window as { caches?:unknown }).caches;

      await expect(mount('false')).resolves.toBeUndefined();
    });

    it('swallows a rejected cache listing', async () => {
      const unhandled = vi.fn();
      window.addEventListener('unhandledrejection', unhandled);
      keys.mockRejectedValue(new Error('SecurityError'));

      await mount('false');
      await ctx.nextFrame();

      expect(keys).toHaveBeenCalled();
      expect(unhandled).not.toHaveBeenCalled();
      window.removeEventListener('unhandledrejection', unhandled);
    });

    it('swallows a synchronous cache error', async () => {
      keys.mockImplementation(() => { throw new Error('boom'); });

      await mount('false');

      expect(keys).toHaveBeenCalled();
    });
  });

  describe('offline fallback for Turbo visits', () => {
    const fallbackUrl = () => new URL('#offline-fallback', window.location.href);

    function failFetch(request:Record<string, unknown>, target:EventTarget = document) {
      target.dispatchEvent(new CustomEvent('turbo:fetch-request-error', {
        bubbles: true,
        cancelable: true,
        detail: { request, error: new TypeError('Failed to fetch') },
      }));
    }

    function control(controller:object|undefined) {
      Object.defineProperty(navigator, 'serviceWorker', { value: { register, controller }, configurable: true });
    }

    afterEach(() => {
      window.location.hash = '';
    });

    it('navigates to the failed url when the worker controls the page', async () => {
      control({});
      await mount();

      failFetch({ method: 'get', url: fallbackUrl() });

      expect(window.location.hash).toBe('#offline-fallback');
    });

    it('does nothing when the worker does not control the page', async () => {
      control(null as unknown as undefined);
      await mount();

      failFetch({ method: 'get', url: fallbackUrl() });

      expect(window.location.hash).toBe('');
    });

    it('does nothing for non-GET requests', async () => {
      control({});
      await mount();

      failFetch({ method: 'post', url: fallbackUrl() });

      expect(window.location.hash).toBe('');
    });

    it('does nothing for cross-origin requests', async () => {
      control({});
      await mount();

      failFetch({ method: 'get', url: new URL('https://example.com/#offline-fallback') });

      expect(window.location.hash).toBe('');
    });

    it('does nothing for requests made by a turbo frame', async () => {
      control({});
      await mount();
      const frame = document.createElement('turbo-frame');
      ctx.container.appendChild(frame);

      failFetch({ method: 'get', url: fallbackUrl() }, frame);

      expect(window.location.hash).toBe('');
    });

    it('stops listening once disconnected', async () => {
      control({});
      await mount();
      ctx.container.innerHTML = '';
      await ctx.nextFrame();

      failFetch({ method: 'get', url: fallbackUrl() });

      expect(window.location.hash).toBe('');
    });
  });
});
