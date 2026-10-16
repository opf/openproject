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
import PwaPushResumeController from './pwa-push-resume.controller';

describe('PwaPushResumeController', () => {
  let ctx:StimulusTestContext;
  let fetchMock:ReturnType<typeof vi.fn<(...args:unknown[]) => Promise<unknown>>>;
  let getSubscription:ReturnType<typeof vi.fn>;

  const endpoint = 'https://push.example/mine';

  async function mount(session = 'session-a', extra = '') {
    ctx = await setupStimulusTest({ controllers: { 'pwa-push-resume': PwaPushResumeController } });
    await ctx.mount(`
      <div data-controller="pwa-push-resume"
           data-pwa-push-resume-url-value="/my/push_subscriptions"
           data-pwa-push-resume-session-value="${session}"></div>
      ${extra}
    `);
    await ctx.nextFrame();
  }

  beforeEach(() => {
    getSubscription = vi.fn().mockResolvedValue({ endpoint });
    fetchMock = vi.fn<(...args:unknown[]) => Promise<unknown>>()
      .mockImplementation(() => Promise.resolve(new Response(null, { status: 204 })));
    const registration = { pushManager: { getSubscription } };

    document.body.dataset.renderedAt = new Date().toISOString();
    localStorage.clear();
    vi.stubGlobal('isSecureContext', true);
    vi.stubGlobal('PushManager', class {});
    vi.stubGlobal('Notification', { permission: 'granted' });
    vi.stubGlobal('fetch', fetchMock);
    Object.defineProperty(navigator, 'serviceWorker', {
      value: { getRegistration: vi.fn().mockResolvedValue(registration) },
      configurable: true,
    });
  });

  afterEach(() => {
    ctx.dispose();
    vi.unstubAllGlobals();
    delete (navigator as { serviceWorker?:unknown }).serviceWorker;
    delete document.body.dataset.renderedAt;
    document.documentElement.removeAttribute('data-turbo-preview');
    localStorage.clear();
  });

  it('posts the endpoint once as a resume', async () => {
    await mount();

    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('/my/push_subscriptions');
    expect(init.method?.toLowerCase()).toBe('post');
    expect(JSON.parse(init.body as string)).toEqual({ push_endpoint: endpoint, resume: true });
    expect(new Headers(init.headers).get('Accept')).toContain('text/vnd.turbo-stream.html');
  });

  it('does not post again for the same session but does for a new one', async () => {
    await mount();
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));
    ctx.dispose();

    await mount();
    await ctx.nextFrame();
    expect(fetchMock).toHaveBeenCalledTimes(1);
    ctx.dispose();

    await mount('session-b');
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2));
  });

  it('does not post for an earlier session that was already attempted', async () => {
    await mount('session-a');
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));
    ctx.dispose();

    await mount('session-b');
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2));
    ctx.dispose();

    await mount('session-a');
    await ctx.nextFrame();
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('does not post when permission has not been granted', async () => {
    vi.stubGlobal('Notification', { permission: 'default' });
    await mount();

    expect(getSubscription).not.toHaveBeenCalled();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('does not post on a page that handles push itself', async () => {
    await mount('session-a', '<div data-controller="my--push-subscription"></div>');

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('does not post while Turbo renders a preview', async () => {
    document.documentElement.setAttribute('data-turbo-preview', '');
    await mount();

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('does not post from a page rendered more than two minutes ago', async () => {
    document.body.dataset.renderedAt = new Date(Date.now() - 3 * 60 * 1000).toISOString();
    await mount();

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('does not post without a browser subscription', async () => {
    getSubscription.mockResolvedValue(null);
    await mount();

    expect(getSubscription).toHaveBeenCalled();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('tries again on the next page when the request was rejected', async () => {
    fetchMock.mockRejectedValueOnce(new Error('offline'));
    await mount();
    await vi.waitFor(() => expect(localStorage.getItem('push-resume-attempted')).toBe('[]'));
    ctx.dispose();

    await mount();
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2));
  });

  it('tries again on the next page when the server answered with an error', async () => {
    fetchMock.mockResolvedValueOnce(new Response('', { status: 503 }));
    await mount();
    await vi.waitFor(() => expect(localStorage.getItem('push-resume-attempted')).toBe('[]'));
    ctx.dispose();

    await mount();
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2));
  });

  it('swallows a rejected request', async () => {
    const unhandled = vi.fn();
    window.addEventListener('unhandledrejection', unhandled);
    fetchMock.mockRejectedValue(new Error('offline'));

    await mount();
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalled());
    await ctx.nextFrame();

    expect(unhandled).not.toHaveBeenCalled();
    window.removeEventListener('unhandledrejection', unhandled);
  });

  it('swallows a rejected registration lookup', async () => {
    const unhandled = vi.fn();
    window.addEventListener('unhandledrejection', unhandled);
    (navigator.serviceWorker.getRegistration as ReturnType<typeof vi.fn>).mockRejectedValue(new Error('SecurityError'));

    await mount();
    await ctx.nextFrame();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(unhandled).not.toHaveBeenCalled();
    window.removeEventListener('unhandledrejection', unhandled);
  });
});
