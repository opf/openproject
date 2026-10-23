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
import { setupStimulusTest, type StimulusTestContext } from '../../../test-helpers';
import PushSubscriptionController from './push-subscription.controller';

type AsyncSpy = ReturnType<typeof vi.fn<(...args:unknown[]) => Promise<unknown>>>;

describe('PushSubscriptionController', () => {
  let ctx:StimulusTestContext;
  let fetchMock:AsyncSpy;
  let unsubscribe:ReturnType<typeof vi.fn>;
  let subscribe:AsyncSpy;
  let getSubscription:ReturnType<typeof vi.fn>;
  let getRegistration:ReturnType<typeof vi.fn>;
  let requestPermission:AsyncSpy;
  let serviceWorker:{ getRegistration:ReturnType<typeof vi.fn>; ready:Promise<unknown> };
  let registration:{ active?:object; pushManager:{ getSubscription:ReturnType<typeof vi.fn>; subscribe:AsyncSpy } };

  const MESSAGES = {
    unsupported: 'Unsupported message',
    blocked: 'Blocked message',
    enabled: 'Enabled message',
    disabled: 'Disabled message',
    error: 'Error message',
    prompting: 'Prompting message',
    subscribing: 'Subscribing message',
    timeout: 'Timeout message',
  };
  const currentKey = { applicationServerKey: new Uint8Array([0xfb, 0xff]) };
  const known = { endpoint: 'https://push.example/known', revokeUrl: '/my/push_subscriptions/1' };

  const visibleBanners = () => Array.from(
    document.querySelectorAll<HTMLElement>('[data-my--push-subscription-target="banner"]:not([hidden])'),
  );
  const status = () => document
    .querySelector('[data-my--push-subscription-target="banner"]:not([hidden]) [data-my--push-subscription-target="message"]')!
    .textContent;
  const liveRegion = () => document.querySelector('[data-my--push-subscription-target="liveRegion"]')!;
  const expectOnlyBanner = (scheme:string) => {
    expect(visibleBanners().map((banner) => banner.dataset.scheme)).toEqual([scheme]);
  };
  const enableButton = () => document.getElementById('enable') as HTMLButtonElement;
  const disableButton = () => document.getElementById('disable') as HTMLButtonElement;
  const retryButton = () => document.getElementById('retry') as HTMLButtonElement;
  const settled = () => vi.waitFor(() => {
    [enableButton(), disableButton(), retryButton()].forEach((action) => expect(action.disabled).toBe(false));
  });
  async function mount({ settle = true, subscriptions = [known] }:{ settle?:boolean; subscriptions?:object[] } = {}) {
    ctx = await setupStimulusTest({ controllers: { 'my--push-subscription': PushSubscriptionController } });
    const initialScheme = subscriptions.some((entry) => (entry as { current?:boolean }).current) ? 'success' : 'warning';
    const initialMessage = MESSAGES[initialScheme === 'success' ? 'enabled' : 'disabled'];
    const banner = (scheme:string, action?:{ id:string; handler:string }) => `
        <div data-my--push-subscription-target="banner" data-scheme="${scheme}"${scheme === initialScheme ? '' : ' hidden'}>
          <span data-my--push-subscription-target="message" data-scheme="${scheme}">${scheme === initialScheme ? initialMessage : ''}</span>
          ${action ? `<button id="${action.id}" disabled data-my--push-subscription-target="action" data-scheme="${scheme}"
                  data-action="my--push-subscription#${action.handler}">${action.id}</button>` : ''}
        </div>`;
    await ctx.mount(`
      <div data-controller="my--push-subscription"
           data-my--push-subscription-vapid-public-key-value="-_8"
           data-my--push-subscription-create-url-value="/my/push_subscriptions"
           data-my--push-subscription-subscriptions-value='${JSON.stringify(subscriptions)}'
           data-my--push-subscription-messages-value='${JSON.stringify(MESSAGES)}'>
        <div data-my--push-subscription-target="liveRegion" role="status">${initialMessage}</div>
        ${banner('default')}
        ${banner('warning', { id: 'enable', handler: 'enable' })}
        ${banner('success', { id: 'disable', handler: 'disable' })}
        ${banner('danger', { id: 'retry', handler: 'retry' })}
      </div>
    `);
    if (settle) await settled();
  }

  const deferred = <T>() => {
    let resolve!:(value:T) => void;
    const promise = new Promise<T>((res) => { resolve = res; });
    return { promise, resolve };
  };

  beforeEach(() => {
    unsubscribe = vi.fn<(...args:unknown[]) => Promise<unknown>>().mockResolvedValue(true);
    subscribe = vi.fn<(...args:unknown[]) => Promise<unknown>>().mockResolvedValue({ endpoint: 'https://push.example/new', unsubscribe });
    requestPermission = vi.fn<(...args:unknown[]) => Promise<unknown>>().mockResolvedValue('granted');
    getSubscription = vi.fn().mockResolvedValue(null);
    registration = { active: {}, pushManager: { getSubscription, subscribe } };
    getRegistration = vi.fn().mockResolvedValue(registration);
    serviceWorker = { getRegistration, ready: Promise.resolve(registration) };
    fetchMock = vi.fn<(...args:unknown[]) => Promise<unknown>>().mockImplementation(() => Promise.resolve(new Response('', { status: 200 })));

    vi.stubGlobal('isSecureContext', true);
    vi.stubGlobal('PushManager', class {});
    vi.stubGlobal('Notification', { permission: 'default', requestPermission });
    vi.stubGlobal('fetch', fetchMock);
    Object.defineProperty(navigator, 'serviceWorker', {
      value: serviceWorker,
      configurable: true,
    });
  });

  afterEach(() => {
    ctx.dispose();
    vi.useRealTimers();
    vi.unstubAllGlobals();
    delete (navigator as { serviceWorker?:unknown }).serviceWorker;
  });

  it('reports an unsupported environment and hides all actions', async () => {
    vi.stubGlobal('PushManager', undefined);
    delete (window as { PushManager?:unknown }).PushManager;
    await mount();

    expect(status()).toBe(MESSAGES.unsupported);
    expectOnlyBanner('default');
  });

  it('reports unsupported when no service worker becomes ready in time', async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    getRegistration.mockResolvedValue(undefined);
    serviceWorker.ready = new Promise(() => undefined);
    await mount({ settle: false });
    await vi.advanceTimersByTimeAsync(5001);
    await settled();

    expect(status()).toBe(MESSAGES.unsupported);
    expectOnlyBanner('default');
  });

  it('waits for a registration that is still installing and shows its subscription', async () => {
    getRegistration.mockResolvedValue(undefined);
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: currentKey });
    await mount();

    expect(status()).toBe(MESSAGES.enabled);
    expectOnlyBanner('success');
    expect(disableButton().hidden).toBe(false);
  });

  it('waits for the worker to become active before subscribing on enable', async () => {
    await mount();
    const pending = deferred<unknown>();
    getRegistration.mockResolvedValue({ pushManager: registration.pushManager });
    serviceWorker.ready = pending.promise;
    enableButton().click();
    await ctx.nextFrame();

    expect(subscribe).not.toHaveBeenCalled();

    pending.resolve(registration);
    await vi.waitFor(() => expect(subscribe).toHaveBeenCalledTimes(1));
  });

  it('reports blocked notifications when permission is denied', async () => {
    vi.stubGlobal('Notification', { permission: 'denied' });
    await mount();

    expect(status()).toBe(MESSAGES.blocked);
    expectOnlyBanner('warning');
    expect(enableButton().hidden).toBe(true);
  });

  it('shows an error when reading the current subscription fails and recovers on try again', async () => {
    getSubscription.mockRejectedValue(new Error('boom'));
    await mount();

    expect(status()).toBe(MESSAGES.error);
    expectOnlyBanner('danger');
    expect(retryButton().hidden).toBe(false);

    getSubscription.mockResolvedValue(null);
    retryButton().click();
    await vi.waitFor(() => expect(status()).toBe(MESSAGES.disabled));
    await settled();

    expectOnlyBanner('warning');
    expect(subscribe).not.toHaveBeenCalled();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('keeps all actions disabled until the initial sync finishes', async () => {
    const pending = deferred<null>();
    getSubscription.mockReturnValue(pending.promise);
    await mount({ settle: false });

    expect(enableButton().disabled).toBe(true);
    expect(disableButton().disabled).toBe(true);

    pending.resolve(null);
    await settled();
    expect(status()).toBe(MESSAGES.disabled);
  });

  it('shows the enabled state for a subscription known to the server', async () => {
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: currentKey });
    await mount();

    expect(status()).toBe(MESSAGES.enabled);
    expectOnlyBanner('success');
    expect(disableButton().hidden).toBe(false);
    expect(unsubscribe).not.toHaveBeenCalled();
  });

  it('registers a dormant subscription again instead of dropping it', async () => {
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: currentKey });
    await mount({ subscriptions: [{ ...known, dormant: true }] });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('/my/push_subscriptions');
    expect(JSON.parse(init.body as string)).toEqual({ push_endpoint: known.endpoint });
    expect(unsubscribe).not.toHaveBeenCalled();
    expect(status()).toBe(MESSAGES.enabled);
  });

  it('drops a browser subscription the server does not know and shows the disabled state', async () => {
    getSubscription.mockResolvedValue({ endpoint: 'https://push.example/stale', unsubscribe });
    await mount();

    expect(unsubscribe).toHaveBeenCalled();
    expect(status()).toBe(MESSAGES.disabled);
    expectOnlyBanner('warning');
    expect(enableButton().hidden).toBe(false);
  });

  it('drops a subscription bound to a previous VAPID key and shows the disabled state', async () => {
    const previousKey = { applicationServerKey: new Uint8Array([0x01, 0x02]) };
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: previousKey });
    await mount();

    expect(unsubscribe).toHaveBeenCalled();
    expect(fetchMock).not.toHaveBeenCalled();
    expect(status()).toBe(MESSAGES.disabled);
    expectOnlyBanner('warning');
    expect(enableButton().hidden).toBe(false);
  });

  it('keeps a subscription whose key is unavailable', async () => {
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: { applicationServerKey: null } });
    await mount();

    expect(unsubscribe).not.toHaveBeenCalled();
    expect(status()).toBe(MESSAGES.enabled);
  });

  it('revokes the server row for this device when the browser lost its subscription', async () => {
    const mine = { endpoint: 'https://push.example/mine', revokeUrl: '/my/push_subscriptions/2', current: true };
    getSubscription.mockResolvedValue(null);
    await mount({ subscriptions: [known, mine] });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe(`${mine.revokeUrl}?silent=true`);
    expect(init.method?.toLowerCase()).toBe('delete');
    expect(status()).toBe(MESSAGES.disabled);
    expectOnlyBanner('warning');
    expect(enableButton().hidden).toBe(false);
  });

  it('revokes the server row for this device when notifications are blocked', async () => {
    const mine = { endpoint: 'https://push.example/mine', revokeUrl: '/my/push_subscriptions/2', current: true };
    vi.stubGlobal('Notification', { permission: 'denied' });
    await mount({ subscriptions: [mine] });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe(`${mine.revokeUrl}?silent=true`);
    expect(init.method?.toLowerCase()).toBe('delete');
    expect(status()).toBe(MESSAGES.blocked);
  });

  it('sends no DELETE when no row belongs to this device', async () => {
    getSubscription.mockResolvedValue(null);
    await mount({ subscriptions: [{ ...known, current: false }] });

    expect(fetchMock).not.toHaveBeenCalled();
    expect(status()).toBe(MESSAGES.disabled);
  });

  it('shows the disabled state without a subscription', async () => {
    await mount();

    expect(status()).toBe(MESSAGES.disabled);
    expectOnlyBanner('warning');
    expect(enableButton().hidden).toBe(false);
  });

  it('subscribes with the decoded key and posts the endpoint to the server on enable', async () => {
    await mount();
    enableButton().click();
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));

    const options = subscribe.mock.calls[0][0] as { userVisibleOnly:boolean; applicationServerKey:Uint8Array };
    expect(options.userVisibleOnly).toBe(true);
    expect(options.applicationServerKey).toBeInstanceOf(Uint8Array);
    expect(Array.from(options.applicationServerKey)).toEqual([0xfb, 0xff]);

    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('/my/push_subscriptions');
    expect(init.method?.toLowerCase()).toBe('post');
    expect(JSON.parse(init.body as string)).toEqual({ push_endpoint: 'https://push.example/new' });
    expect(new Headers(init.headers).get('Accept')).toContain('text/vnd.turbo-stream.html');
  });

  it('shows the enabled state locally after a successful enable', async () => {
    await mount();
    enableButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.enabled));
    expectOnlyBanner('success');
    expect(disableButton().hidden).toBe(false);
  });

  it('subscribes and posts only once on a double click', async () => {
    await mount();
    enableButton().click();
    enableButton().click();
    await settled();

    expect(subscribe).toHaveBeenCalledTimes(1);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('disables both buttons while a request is in flight', async () => {
    const pending = deferred<{ endpoint:string; unsubscribe:typeof unsubscribe }>();
    subscribe.mockReturnValue(pending.promise);
    await mount();
    enableButton().click();

    expect(enableButton().disabled).toBe(true);
    expect(disableButton().disabled).toBe(true);
    expect(retryButton().disabled).toBe(true);

    pending.resolve({ endpoint: 'https://push.example/new', unsubscribe });
    await settled();
  });

  it('does not let a slow initial sync unsubscribe a subscription created by enable', async () => {
    const pending = deferred<{ endpoint:string; unsubscribe:typeof unsubscribe }>();
    getSubscription.mockReturnValue(pending.promise);
    await mount({ settle: false });

    enableButton().disabled = false;
    enableButton().click();
    await vi.waitFor(() => expect(status()).toBe(MESSAGES.enabled));

    pending.resolve({ endpoint: 'https://push.example/new', unsubscribe });
    await ctx.nextFrame();

    expect(unsubscribe).not.toHaveBeenCalled();
    expect(status()).toBe(MESSAGES.enabled);
    expectOnlyBanner('success');
    expect(disableButton().hidden).toBe(false);
  });

  it('shows an error and does not post when subscribing fails', async () => {
    subscribe.mockRejectedValue(new Error('failed'));
    await mount();
    enableButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.error));
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('shows the blocked state when subscribing fails because permission was denied', async () => {
    subscribe.mockImplementation(() => {
      vi.stubGlobal('Notification', { permission: 'denied' });
      return Promise.reject(new Error('denied'));
    });
    await mount();
    enableButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.blocked));
    expect(fetchMock).not.toHaveBeenCalled();
    expectOnlyBanner('warning');
    expect(enableButton().hidden).toBe(true);
  });

  it('unsubscribes and shows an error when the server rejects the subscription', async () => {
    fetchMock.mockImplementation(() => Promise.resolve(new Response('', { status: 422 })));
    await mount();
    enableButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.error));
    expect(unsubscribe).toHaveBeenCalled();
  });

  it('asks for permission before subscribing when it has not been decided', async () => {
    const answer = deferred<string>();
    requestPermission.mockReturnValue(answer.promise);
    await mount();
    enableButton().click();

    expect(requestPermission).toHaveBeenCalledTimes(1);
    expect(status()).toBe(MESSAGES.prompting);
    expect(enableButton().disabled).toBe(true);
    expect(subscribe).not.toHaveBeenCalled();

    answer.resolve('granted');
    await vi.waitFor(() => expect(subscribe).toHaveBeenCalledTimes(1));
  });

  it('shows the blocked state and does not subscribe when the permission prompt is denied', async () => {
    requestPermission.mockResolvedValue('denied');
    await mount();
    enableButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.blocked));
    expect(subscribe).not.toHaveBeenCalled();
    expectOnlyBanner('warning');
    expect(enableButton().hidden).toBe(true);
  });

  it('skips the permission prompt when permission is already granted', async () => {
    vi.stubGlobal('Notification', { permission: 'granted', requestPermission });
    await mount();
    enableButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.enabled));
    expect(requestPermission).not.toHaveBeenCalled();
  });

  it('shows a timeout and unsubscribes a late subscription when the browser takes too long to subscribe', async () => {
    const pending = deferred<{ endpoint:string; unsubscribe:typeof unsubscribe }>();
    subscribe.mockReturnValue(pending.promise);
    await mount();
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    enableButton().click();
    await vi.advanceTimersByTimeAsync(0);

    expect(status()).toBe(MESSAGES.subscribing);

    await vi.advanceTimersByTimeAsync(30001);
    await settled();

    expect(status()).toBe(MESSAGES.timeout);
    expectOnlyBanner('danger');
    expect(retryButton().hidden).toBe(false);
    expect(fetchMock).not.toHaveBeenCalled();

    pending.resolve({ endpoint: 'https://push.example/late', unsubscribe });
    await vi.waitFor(() => expect(unsubscribe).toHaveBeenCalled());
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('keeps a late subscription that a second enable has registered in the meantime', async () => {
    const lateUnsubscribe = vi.fn<(...args:unknown[]) => Promise<unknown>>().mockResolvedValue(true);
    const pending = deferred<{ endpoint:string; unsubscribe:typeof unsubscribe }>();
    subscribe.mockReturnValueOnce(pending.promise);
    await mount();
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    enableButton().click();
    await vi.advanceTimersByTimeAsync(30001);
    await settled();
    expect(status()).toBe(MESSAGES.timeout);

    enableButton().click();
    await vi.waitFor(() => expect(status()).toBe(MESSAGES.enabled));

    pending.resolve({ endpoint: 'https://push.example/new', unsubscribe: lateUnsubscribe });
    await vi.advanceTimersByTimeAsync(0);
    expect(lateUnsubscribe).not.toHaveBeenCalled();
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('sends a DELETE to the revoke url of the current subscription on disable', async () => {
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: currentKey });
    await mount();
    disableButton().click();
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));

    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe(known.revokeUrl);
    expect(init.method?.toLowerCase()).toBe('delete');
    expect(new Headers(init.headers).get('Accept')).toContain('text/vnd.turbo-stream.html');
  });

  it('unsubscribes the browser and shows the disabled state after a successful disable', async () => {
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: currentKey });
    await mount();
    disableButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.disabled));
    expect(unsubscribe).toHaveBeenCalled();
    expectOnlyBanner('warning');
    expect(enableButton().hidden).toBe(false);
  });

  it('shows the error banner when the DELETE fails', async () => {
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: currentKey });
    fetchMock.mockImplementation(() => Promise.resolve(new Response('', { status: 500 })));
    await mount();
    disableButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.error));
    expectOnlyBanner('danger');
    expect(retryButton().hidden).toBe(false);
    expect(unsubscribe).not.toHaveBeenCalled();
  });

  it('sends no request when the current subscription has no known revoke url', async () => {
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: currentKey });
    await mount();
    getSubscription.mockResolvedValue({ endpoint: 'https://push.example/other', unsubscribe });
    disableButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.error));
    expect(fetchMock).not.toHaveBeenCalled();
    expectOnlyBanner('danger');
    expect(retryButton().hidden).toBe(false);
  });

  it('mirrors the message into the live region and clears the message of hidden banners', async () => {
    await mount();

    expect(liveRegion().textContent).toBe(MESSAGES.disabled);
    enableButton().click();
    await vi.waitFor(() => expect(liveRegion().textContent).toBe(MESSAGES.enabled));

    const warningMessage = document.querySelector('[data-my--push-subscription-target="message"][data-scheme="warning"]')!;
    expect(warningMessage.textContent).toBe('');
  });

  it('retries the disable when a disable failed', async () => {
    getSubscription.mockResolvedValue({ endpoint: known.endpoint, unsubscribe, options: currentKey });
    fetchMock
      .mockResolvedValueOnce(new Response('', { status: 500 }))
      .mockResolvedValueOnce(new Response('', { status: 200 }));
    await mount();
    disableButton().click();
    await vi.waitFor(() => expect(status()).toBe(MESSAGES.error));

    retryButton().click();
    await vi.waitFor(() => expect(status()).toBe(MESSAGES.disabled));
    await settled();

    expect(fetchMock).toHaveBeenCalledTimes(2);
    const [, init] = fetchMock.mock.calls[1] as [string, RequestInit];
    expect(init.method?.toLowerCase()).toBe('delete');
    expect(subscribe).not.toHaveBeenCalled();
    expect(unsubscribe).toHaveBeenCalledTimes(1);
    expectOnlyBanner('warning');
  });

  it('runs the enable flow from the try again action of the error banner', async () => {
    subscribe.mockRejectedValueOnce(new Error('failed'));
    await mount();
    enableButton().click();
    await vi.waitFor(() => expect(status()).toBe(MESSAGES.error));

    retryButton().click();

    await vi.waitFor(() => expect(status()).toBe(MESSAGES.enabled));
    expect(subscribe).toHaveBeenCalledTimes(2);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});
