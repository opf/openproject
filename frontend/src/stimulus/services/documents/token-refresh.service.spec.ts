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

import type { Mock } from 'vitest';
import type { HocuspocusProvider } from '@hocuspocus/provider';
import { RefreshError, TokenRefreshService } from './token-refresh.service';

const URL = '/documents/1/refresh_token';
const TOKEN = { encrypted_token: 'fresh', expires_in_seconds: 100 };
const FIRST_REFRESH_MS = 8001; // 80% of a 10 second token, plus 1 ms of slack
const RETRY_BUDGET_MS = 3 * 5000 + 1;

// Plain object so the body resolves via microtasks, which fake timers can flush.
const fakeResponse = (status:number):Response => ({
  ok: status >= 200 && status < 300,
  status,
  statusText: '',
  json: () => Promise.resolve(TOKEN),
}) as Response;

const classify = async ():Promise<RefreshError> => {
  try {
    await TokenRefreshService.fetchToken(URL);
  } catch (error) {
    return error as RefreshError;
  }
  throw new Error('fetchToken did not throw');
};

describe('TokenRefreshService', () => {
  let fetchSpy:ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    fetchSpy = vi.spyOn(window, 'fetch');
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
    document.head.querySelector('meta[name="csrf-token"]')?.remove();
  });

  describe('fetchToken', () => {
    it.each([401, 404])('treats %i as access denied and not retryable', async (status) => {
      fetchSpy.mockResolvedValue(new Response('', { status }));

      const error = await classify();

      expect(error.isAccessDenied).toBe(true);
      expect(error.isRetryable).toBe(false);
    });

    it.each([503, 429, 408])('treats %i as transient', async (status) => {
      fetchSpy.mockResolvedValue(new Response('', { status }));

      const error = await classify();

      expect(error.isAccessDenied).toBe(false);
      expect(error.isRetryable).toBe(true);
    });

    it('treats a network error as transient', async () => {
      fetchSpy.mockRejectedValue(new TypeError('Failed to fetch'));

      const error = await classify();

      expect(error).toBeInstanceOf(RefreshError);
      expect(error.isAccessDenied).toBe(false);
      expect(error.isRetryable).toBe(true);
    });

    it('treats a 2xx with a non-JSON body as transient', async () => {
      fetchSpy.mockResolvedValue(new Response('<html>portal</html>', { status: 200 }));

      const error = await classify();

      expect(error.isAccessDenied).toBe(false);
      expect(error.isRetryable).toBe(true);
    });

    it.each([{}, { encrypted_token: '', expires_in_seconds: 100 }, { encrypted_token: 'x', expires_in_seconds: 0 }])(
      'treats a 2xx with an unusable payload %j as transient',
      async (payload) => {
        fetchSpy.mockResolvedValue(new Response(JSON.stringify(payload), { status: 200 }));

        const error = await classify();

        expect(error.isAccessDenied).toBe(false);
        expect(error.isRetryable).toBe(true);
      },
    );

    it('treats 422 as neither denied nor retryable', async () => {
      fetchSpy.mockResolvedValue(new Response('', { status: 422 }));

      const error = await classify();

      expect(error.isAccessDenied).toBe(false);
      expect(error.isRetryable).toBe(false);
    });

    it('sends the Accept and CSRF headers', async () => {
      document.head.insertAdjacentHTML('beforeend', '<meta name="csrf-token" content="csrf-123">');
      fetchSpy.mockResolvedValue(new Response(JSON.stringify(TOKEN), { status: 200 }));

      await TokenRefreshService.fetchToken(URL);

      const headers = fetchSpy.mock.calls[0][1]?.headers as Record<string, string>;
      expect(headers.Accept).toBe('application/json');
      expect(headers['X-CSRF-Token']).toBe('csrf-123');
    });
  });

  describe('scheduling', () => {
    let provider:HocuspocusProvider;
    let sendToken:Mock<() => Promise<void>>;
    let onToken:Mock<(token:string) => void>;
    let onFailure:Mock<(error:RefreshError) => void>;
    let service:TokenRefreshService;

    beforeEach(() => {
      vi.useFakeTimers();
      sendToken = vi.fn<() => Promise<void>>().mockResolvedValue(undefined);
      provider = { sendToken } as unknown as HocuspocusProvider;
      onToken = vi.fn<(token:string) => void>();
      onFailure = vi.fn<(error:RefreshError) => void>();
      service = new TokenRefreshService(provider, URL, onToken, onFailure);
    });

    afterEach(() => service.destroy());

    it('hands the token over, syncs it and schedules the next refresh', async () => {
      fetchSpy.mockResolvedValue(fakeResponse(200));
      service.scheduleRefresh(10);

      await vi.advanceTimersByTimeAsync(FIRST_REFRESH_MS);
      expect(onToken).toHaveBeenCalledWith('fresh');
      expect(sendToken).toHaveBeenCalledOnce();
      expect(fetchSpy).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(80001);
      expect(fetchSpy).toHaveBeenCalledTimes(2);
      expect(onFailure).not.toHaveBeenCalled();
    });

    it('reports access denial once and does not retry', async () => {
      fetchSpy.mockResolvedValue(fakeResponse(404));
      service.scheduleRefresh(10);

      await vi.advanceTimersByTimeAsync(FIRST_REFRESH_MS + 60000);

      expect(fetchSpy).toHaveBeenCalledTimes(1);
      expect(onFailure).toHaveBeenCalledOnce();
      expect(onFailure.mock.calls[0][0].isAccessDenied).toBe(true);
    });

    it('retries transient failures, then reports once and stops', async () => {
      fetchSpy.mockResolvedValue(fakeResponse(503));
      service.scheduleRefresh(10);

      await vi.advanceTimersByTimeAsync(FIRST_REFRESH_MS + RETRY_BUDGET_MS);
      expect(fetchSpy).toHaveBeenCalledTimes(4);
      expect(onFailure).toHaveBeenCalledOnce();
      expect(onFailure.mock.calls[0][0].isAccessDenied).toBe(false);

      await vi.advanceTimersByTimeAsync(120000);
      expect(fetchSpy).toHaveBeenCalledTimes(4);
      expect(onFailure).toHaveBeenCalledOnce();
    });

    it('gets a fresh retry budget when rescheduled after giving up', async () => {
      fetchSpy.mockResolvedValue(fakeResponse(503));
      service.scheduleRefresh(10);
      await vi.advanceTimersByTimeAsync(FIRST_REFRESH_MS + RETRY_BUDGET_MS);
      expect(onFailure).toHaveBeenCalledOnce();

      service.scheduleRefresh(10);
      await vi.advanceTimersByTimeAsync(FIRST_REFRESH_MS);
      expect(fetchSpy).toHaveBeenCalledTimes(5);
      expect(onFailure).toHaveBeenCalledOnce();

      await vi.advanceTimersByTimeAsync(RETRY_BUDGET_MS);
      expect(fetchSpy).toHaveBeenCalledTimes(8);
      expect(onFailure).toHaveBeenCalledTimes(2);
    });

    it.each([200, 401])('stays silent when destroyed while a fetch is pending and then answers %i', async (status) => {
      let answer:() => void = () => {};
      fetchSpy.mockReturnValue(new Promise<Response>((resolve) => {
        answer = () => resolve(fakeResponse(status));
      }));
      service.scheduleRefresh(10);
      await vi.advanceTimersByTimeAsync(FIRST_REFRESH_MS);
      expect(fetchSpy).toHaveBeenCalledTimes(1);

      service.destroy();
      answer();
      await vi.advanceTimersByTimeAsync(120000);

      expect(onToken).not.toHaveBeenCalled();
      expect(sendToken).not.toHaveBeenCalled();
      expect(onFailure).not.toHaveBeenCalled();
      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });

    describe('acquireToken', () => {
      const failures = (count:number):void => {
        for (let i = 0; i < count; i += 1) {
          fetchSpy.mockResolvedValueOnce(fakeResponse(503));
        }
      };

      it('retries transient failures with doubling delays capped at 30 seconds, then resolves', async () => {
        failures(7);
        fetchSpy.mockResolvedValue(fakeResponse(200));

        const token = service.acquireToken();
        await vi.advanceTimersByTimeAsync(0);
        expect(fetchSpy).toHaveBeenCalledTimes(1);

        const delays = [1000, 2000, 4000, 8000, 16000, 30000, 30000];
        let expectedCalls = 1;
        for (const delay of delays) {
          await vi.advanceTimersByTimeAsync(delay - 1);
          expect(fetchSpy).toHaveBeenCalledTimes(expectedCalls);

          await vi.advanceTimersByTimeAsync(1);
          expectedCalls += 1;
          expect(fetchSpy).toHaveBeenCalledTimes(expectedCalls);
        }

        await expect(token).resolves.toEqual(TOKEN);
      });

      it.each([
        [401, true],
        [422, false],
      ])('rejects at once without retrying on %i', async (status, isAccessDenied) => {
        fetchSpy.mockResolvedValue(fakeResponse(status));

        const outcome = service.acquireToken().catch((error:RefreshError) => error);
        await vi.advanceTimersByTimeAsync(120000);

        const error = await outcome;
        expect(error).toBeInstanceOf(RefreshError);
        expect((error as RefreshError).isAccessDenied).toBe(isAccessDenied);
        expect(fetchSpy).toHaveBeenCalledTimes(1);
      });

      it('stops retrying when destroyed during the wait', async () => {
        fetchSpy.mockResolvedValue(fakeResponse(503));

        const outcome = service.acquireToken().catch((error:RefreshError) => error);
        await vi.advanceTimersByTimeAsync(0);
        expect(fetchSpy).toHaveBeenCalledTimes(1);

        service.destroy();
        await vi.advanceTimersByTimeAsync(120000);

        const error = await outcome as RefreshError;
        expect(error.message).toBe('Token service destroyed');
        expect(error.isAccessDenied).toBe(false);
        expect(fetchSpy).toHaveBeenCalledTimes(1);
      });

      it.each([401, 200])('reports a destroyed service, not the outcome, when the pending fetch answers %i', async (status) => {
        let answer:() => void = () => {};
        fetchSpy.mockReturnValue(new Promise<Response>((resolve) => {
          answer = () => resolve(fakeResponse(status));
        }));

        const outcome = service.acquireToken().catch((error:RefreshError) => error);
        await vi.advanceTimersByTimeAsync(0);

        service.destroy();
        answer();
        await vi.advanceTimersByTimeAsync(120000);

        const error = await outcome as RefreshError;
        expect(error.message).toBe('Token service destroyed');
        expect(error.isAccessDenied).toBe(false);
        expect(fetchSpy).toHaveBeenCalledTimes(1);
      });

      it('shares one fetch between concurrent callers and starts a new one after it settles', async () => {
        fetchSpy.mockResolvedValue(fakeResponse(200));

        const [first, second] = await Promise.all([service.acquireToken(), service.acquireToken()]);
        expect(first).toBe(second);
        expect(fetchSpy).toHaveBeenCalledTimes(1);

        fetchSpy.mockResolvedValue(fakeResponse(401));
        await expect(service.acquireToken()).rejects.toBeInstanceOf(RefreshError);
        expect(fetchSpy).toHaveBeenCalledTimes(2);

        fetchSpy.mockResolvedValue(fakeResponse(200));
        await expect(service.acquireToken()).resolves.toEqual(TOKEN);
        expect(fetchSpy).toHaveBeenCalledTimes(3);
      });

      it('resumes the periodic refresh after success', async () => {
        fetchSpy.mockResolvedValue(fakeResponse(200));

        await service.acquireToken();
        expect(fetchSpy).toHaveBeenCalledTimes(1);

        await vi.advanceTimersByTimeAsync(80001);
        expect(fetchSpy).toHaveBeenCalledTimes(2);
        expect(onToken).toHaveBeenCalledWith('fresh');
      });
    });
  });
});
