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

import { SIGN_OUT_TIMEOUT_MS } from './constants';
import type { Notifications as NotificationsType } from './notifications';
import type { PushHandler as PushHandlerType } from './push-handler';
import type { PushState as PushStateType } from './push-state';

describe('PushHandler badge', () => {
  let PushHandler:typeof PushHandlerType;
  let Notifications:typeof NotificationsType;
  let PushState:typeof PushStateType;
  let handler:PushHandlerType;
  const setAppBadge = vi.fn().mockResolvedValue(undefined);
  const clearAppBadge = vi.fn().mockResolvedValue(undefined);
  let fetchSpy:ReturnType<typeof vi.spyOn>;

  const notification = (tag:string) => ({ tag, close: vi.fn() });
  const open = (...notifications:ReturnType<typeof notification>[]) => {
    vi.stubGlobal('registration', { getNotifications: vi.fn().mockResolvedValue(notifications) });
  };
  const summaryResponds = (response:Response) => fetchSpy.mockResolvedValue(response);

  beforeAll(async () => {
    vi.stubGlobal('OP_SW', {
      urls: { push: '/api/v3/notifications/summary', signOut: '/logout' },
      cache: { state: 'op-state' },
    });
    vi.stubGlobal('navigator', { setAppBadge, clearAppBadge });
    ({ PushHandler } = await import('./push-handler'));
    ({ Notifications } = await import('./notifications'));
    ({ PushState } = await import('./push-state'));
  });

  beforeEach(() => {
    handler = new PushHandler();
    fetchSpy = vi.spyOn(globalThis, 'fetch');
    vi.stubGlobal('caches', {
      open: vi.fn().mockResolvedValue({ match: vi.fn().mockResolvedValue(undefined), put: vi.fn() }),
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
    setAppBadge.mockClear();
    clearAppBadge.mockClear();
  });

  describe('reconcile with no notification open', () => {
    beforeEach(() => open());

    it('sets the badge to the unread count', async () => {
      summaryResponds(new Response(JSON.stringify({ count: 4, groups: [] })));

      await handler.reconcile();

      expect(setAppBadge).toHaveBeenCalledWith(4);
    });

    it('clears the badge when nothing is unread', async () => {
      summaryResponds(new Response(JSON.stringify({ count: 0, groups: [] })));

      await handler.reconcile();

      expect(clearAppBadge).toHaveBeenCalled();
    });

    it('leaves the badge alone when the summary is unavailable', async () => {
      summaryResponds(new Response(null, { status: 500 }));

      await handler.reconcile();

      expect(setAppBadge).not.toHaveBeenCalled();
      expect(clearAppBadge).not.toHaveBeenCalled();
    });
  });

  describe('coalescing reconcile messages', () => {
    const MIN_INTERVAL_MS = 10000;
    const send = () => {
      const waitUntil = vi.fn();
      handler.onMessage({ data: { type: 'reconcile' }, origin: 'https://openproject.test', waitUntil } as unknown as ExtendableMessageEvent);
      return waitUntil;
    };
    const unread = () => new Response(JSON.stringify({ count: 2, groups: [] }));

    beforeEach(() => {
      vi.useFakeTimers();
      open();
      fetchSpy.mockImplementation(() => Promise.resolve(unread()));
    });

    afterEach(() => vi.useRealTimers());

    it('runs one reconcile for a burst of messages', async () => {
      const events = [send(), send(), send()];

      await vi.advanceTimersByTimeAsync(0);
      await Promise.all(events.map((waitUntil) => waitUntil.mock.calls[0][0] as Promise<void>));

      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });

    it('runs one trailing reconcile at the end of the interval for a message inside it', async () => {
      send();
      await vi.advanceTimersByTimeAsync(0);
      expect(fetchSpy).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(3000);
      send();
      send();
      await vi.advanceTimersByTimeAsync(MIN_INTERVAL_MS - 3000 - 1);
      expect(fetchSpy).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(1);
      expect(fetchSpy).toHaveBeenCalledTimes(2);

      await vi.advanceTimersByTimeAsync(MIN_INTERVAL_MS);
      expect(fetchSpy).toHaveBeenCalledTimes(2);
    });

    it('runs immediately for a message after the interval', async () => {
      send();
      await vi.advanceTimersByTimeAsync(MIN_INTERVAL_MS + 1);

      send();
      await vi.advanceTimersByTimeAsync(0);

      expect(fetchSpy).toHaveBeenCalledTimes(2);
    });

    it('runs one more reconcile for a message that arrives while one is in flight', async () => {
      let finishFirst:(response:Response) => void = () => undefined;
      fetchSpy.mockImplementationOnce(() => new Promise((resolve) => { finishFirst = resolve; }));

      send();
      await vi.advanceTimersByTimeAsync(0);
      send();
      send();
      finishFirst(unread());
      await vi.advanceTimersByTimeAsync(0);
      expect(fetchSpy).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(MIN_INTERVAL_MS);
      expect(fetchSpy).toHaveBeenCalledTimes(2);
    });

    it('keeps the worker alive until the waiting reconcile has run', async () => {
      send();
      await vi.advanceTimersByTimeAsync(0);
      const waiting = send();
      const settled = vi.fn();
      void (waiting.mock.calls[0][0] as Promise<void>).then(settled);

      await vi.advanceTimersByTimeAsync(MIN_INTERVAL_MS - 1);
      expect(settled).not.toHaveBeenCalled();

      await vi.advanceTimersByTimeAsync(1);
      expect(settled).toHaveBeenCalled();
    });

    it('does not delay a push behind a waiting reconcile', async () => {
      send();
      await vi.advanceTimersByTimeAsync(0);
      send();
      fetchSpy.mockClear();
      vi.stubGlobal('registration', { getNotifications: vi.fn().mockResolvedValue([]), showNotification: vi.fn() });

      handler.onPush({ waitUntil: vi.fn() } as unknown as ExtendableEvent);
      await vi.advanceTimersByTimeAsync(0);

      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('messages from another origin', () => {
    it('triggers neither a reconcile nor an account switch', () => {
      const reconcile = vi.spyOn(handler, 'requestReconcile');
      const switchAccount = vi.spyOn(handler, 'switchAccount');
      const waitUntil = vi.fn();

      [{ type: 'reconcile' }, { type: 'account', userId: 1 }].forEach((data) => {
        handler.onMessage({ data, origin: 'https://evil.test', waitUntil } as unknown as ExtendableMessageEvent);
      });

      expect(reconcile).not.toHaveBeenCalled();
      expect(switchAccount).not.toHaveBeenCalled();
      expect(waitUntil).not.toHaveBeenCalled();
    });
  });

  describe('sign-out', () => {
    let shown:ReturnType<typeof notification>[];
    let clearState:ReturnType<typeof vi.spyOn>;
    let showFallback:ReturnType<typeof vi.spyOn>;

    const deferred = <T>() => {
      let resolve:(value:T) => void = () => undefined;
      const promise = new Promise<T>((done) => { resolve = done; });
      return { promise, resolve };
    };

    beforeEach(() => {
      vi.useFakeTimers();
      shown = [];
      vi.stubGlobal('registration', { getNotifications: vi.fn(() => Promise.resolve([...shown])) });
      clearState = vi.spyOn(PushState, 'clear');
      showFallback = vi.spyOn(Notifications, 'showFallback').mockImplementation(() => {
        shown.push(notification('openproject-unread'));
        return Promise.resolve();
      });
    });

    afterEach(() => vi.useRealTimers());

    it('clears open notifications, remembered push state and the badge once it settles', async () => {
      const previous = notification('openproject-1-wp-9');
      shown.push(previous);

      await handler.signOut(Promise.resolve());

      expect(previous.close).toHaveBeenCalled();
      expect(clearState).toHaveBeenCalled();
      expect(clearAppBadge).toHaveBeenCalled();
    });

    it('leaves nothing of the previous account behind when a push was already in flight', async () => {
      const summary = deferred<Response>();
      const navigation = deferred<undefined>();
      fetchSpy.mockImplementation(() => summary.promise);

      handler.onPush({ waitUntil: vi.fn() } as unknown as ExtendableEvent);
      await vi.advanceTimersByTimeAsync(0);
      const signedOut = handler.signOut(navigation.promise);

      summary.resolve(new Response(JSON.stringify({ count: 2, groups: [{ workPackageId: 9 }] })));
      await vi.advanceTimersByTimeAsync(0);

      expect(showFallback).toHaveBeenCalledTimes(1);
      expect(setAppBadge).not.toHaveBeenCalled();
      expect(shown).toHaveLength(1);

      navigation.resolve(undefined);
      await signedOut;

      const [fallback] = shown;
      expect(fallback.close).toHaveBeenCalled();
      expect(clearState).toHaveBeenCalled();
      expect(clearAppBadge.mock.invocationCallOrder.at(-1)).toBeGreaterThan(showFallback.mock.invocationCallOrder[0]);
    });

    it.each([
      ['rejects', () => Promise.reject(new Error('offline')), 0],
      ['never settles', () => new Promise<never>(() => undefined), SIGN_OUT_TIMEOUT_MS],
    ])('still clears everything when the logout navigation %s', async (_case, navigate, advanceMs) => {
      const signedOut = handler.signOut(navigate());
      const late = notification('openproject-1-wp-9');
      shown.push(late);

      await vi.advanceTimersByTimeAsync(advanceMs);
      await signedOut;

      expect(late.close).toHaveBeenCalled();
      expect(clearState).toHaveBeenCalled();
      expect(clearAppBadge).toHaveBeenCalledTimes(2);
    });
  });

  describe('first account message after the worker starts', () => {
    it('refreshes the badge when it closes another account\'s notifications', async () => {
      const other = notification('openproject-2-wp-9');
      open(other);
      summaryResponds(new Response(JSON.stringify({ count: 3, groups: [] })));

      await handler.switchAccount('1');

      expect(other.close).toHaveBeenCalled();
      expect(setAppBadge).toHaveBeenCalledWith(3);
    });

    it('does not fetch the summary when it closes nothing', async () => {
      open(notification('openproject-1-wp-9'));

      await handler.switchAccount('1');

      expect(fetchSpy).not.toHaveBeenCalled();
    });
  });
});
