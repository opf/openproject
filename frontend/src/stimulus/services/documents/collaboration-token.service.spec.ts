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

import type { HocuspocusProvider } from '@hocuspocus/provider';
import { type Mock, vi } from 'vitest';

import {
  CollaborationTokenError,
  CollaborationTokenService,
  PROVIDER_AUTH_ERROR_EVENT,
} from './collaboration-token.service';

const TOKEN_URL = '/api/v3/documents/1/collaboration_token';

function stubResponse(status:number, body:unknown):Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    statusText: '',
    json: () => Promise.resolve(body),
  } as Response;
}

function tokenResponse(token:string, expiresInSeconds = 300):Response {
  return stubResponse(201, { token, documentName: 'doc', expiresAt: '2026-01-01T00:05:00Z', expiresInSeconds });
}

function errorResponse(status:number):Response {
  return stubResponse(status, { _type: 'Error' });
}

function requestBody(fetchMock:Mock, call:number):unknown {
  const [, init] = fetchMock.mock.calls[call] as [string, RequestInit];
  return JSON.parse(init.body as string);
}

describe('CollaborationTokenService', () => {
  let fetchMock:Mock;

  beforeEach(() => {
    fetchMock = vi.spyOn(window, 'fetch');
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  describe('.fetchToken', () => {
    it('posts an empty body without a previous token', async () => {
      fetchMock.mockResolvedValue(tokenResponse('first'));

      const data = await CollaborationTokenService.fetchToken(TOKEN_URL);

      expect(data.token).toBe('first');
      expect(data.expiresInSeconds).toBe(300);
      expect(fetchMock).toHaveBeenCalledOnce();
      const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
      expect(url).toBe(TOKEN_URL);
      expect(init).toMatchObject({
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
      });
      expect(requestBody(fetchMock, 0)).toEqual({});
    });

    it('sends the previous token in the body', async () => {
      fetchMock.mockResolvedValue(tokenResponse('second'));

      await CollaborationTokenService.fetchToken(TOKEN_URL, 'first');

      expect(requestBody(fetchMock, 0)).toEqual({ token: 'first' });
    });

    it('retries once without the previous token when it is rejected with 422', async () => {
      fetchMock
        .mockResolvedValueOnce(errorResponse(422))
        .mockResolvedValueOnce(tokenResponse('second'));

      const data = await CollaborationTokenService.fetchToken(TOKEN_URL, 'revoked');

      expect(data.token).toBe('second');
      expect(fetchMock).toHaveBeenCalledTimes(2);
      expect(requestBody(fetchMock, 0)).toEqual({ token: 'revoked' });
      expect(requestBody(fetchMock, 1)).toEqual({});
    });

    it('gives up when the retry without the previous token is also rejected', async () => {
      fetchMock.mockResolvedValue(errorResponse(422));

      const error = await CollaborationTokenService.fetchToken(TOKEN_URL, 'revoked').catch((e:unknown) => e);

      expect(fetchMock).toHaveBeenCalledTimes(2);
      expect(error).toBeInstanceOf(CollaborationTokenError);
      expect(error).toMatchObject({ kind: 'http_error', status: 422, isRetryable: false });
    });

    it.each([
      [401, 'session_expired', false],
      [403, 'forbidden', false],
      [404, 'http_error', false],
      [429, 'http_error', true],
      [500, 'http_error', true],
    ])('maps HTTP %i to a %s error (retryable: %s)', async (status, kind, isRetryable) => {
      fetchMock.mockResolvedValue(errorResponse(status));

      const error = await CollaborationTokenService.fetchToken(TOKEN_URL).catch((e:unknown) => e);

      expect(error).toBeInstanceOf(CollaborationTokenError);
      expect(error).toMatchObject({ kind, status, isRetryable });
    });
  });

  describe('#scheduleNextToken', () => {
    let provider:{ sendToken:Mock };
    let currentToken:string;
    let onTokenCreated:Mock;
    let service:CollaborationTokenService;

    beforeEach(() => {
      vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
      provider = { sendToken: vi.fn().mockResolvedValue(undefined) };
      currentToken = 'first';
      onTokenCreated = vi.fn((token:string) => { currentToken = token; });
      service = new CollaborationTokenService(
        provider as unknown as HocuspocusProvider,
        TOKEN_URL,
        () => currentToken,
        onTokenCreated,
      );
    });

    afterEach(() => {
      service.destroy();
    });

    it('creates the next token at 80% of the token lifetime, sending the current token', async () => {
      fetchMock.mockResolvedValue(tokenResponse('second'));

      service.scheduleNextToken(300);

      await vi.advanceTimersByTimeAsync(239_999);
      expect(fetchMock).not.toHaveBeenCalled();

      await vi.advanceTimersByTimeAsync(1);
      expect(fetchMock).toHaveBeenCalledOnce();
      expect(requestBody(fetchMock, 0)).toEqual({ token: 'first' });
      expect(onTokenCreated).toHaveBeenCalledWith('second');
      expect(provider.sendToken).toHaveBeenCalledOnce();
    });

    it('keeps creating tokens, each time sending the latest one', async () => {
      fetchMock
        .mockResolvedValueOnce(tokenResponse('second'))
        .mockResolvedValueOnce(tokenResponse('third'));

      service.scheduleNextToken(300);
      await vi.advanceTimersByTimeAsync(240_000);
      await vi.advanceTimersByTimeAsync(240_000);

      expect(fetchMock).toHaveBeenCalledTimes(2);
      expect(requestBody(fetchMock, 1)).toEqual({ token: 'second' });
      expect(currentToken).toBe('third');
    });

    it('retries retryable errors and emits a token_request error after the retries', async () => {
      fetchMock.mockImplementation(() => Promise.resolve(errorResponse(500)));
      const listener = vi.fn();
      document.addEventListener(PROVIDER_AUTH_ERROR_EVENT, listener);

      service.scheduleNextToken(300);
      await vi.advanceTimersByTimeAsync(240_000);
      await vi.advanceTimersByTimeAsync(3 * 5_000);

      document.removeEventListener(PROVIDER_AUTH_ERROR_EVENT, listener);
      expect(fetchMock).toHaveBeenCalledTimes(4);
      expect(listener).toHaveBeenCalledOnce();
      expect((listener.mock.calls[0][0] as CustomEvent).detail).toMatchObject({ kind: 'token_request' });
      expect(provider.sendToken).not.toHaveBeenCalled();
    });

    it('stops on a non-retryable error', async () => {
      fetchMock.mockResolvedValue(errorResponse(401));
      const listener = vi.fn();
      document.addEventListener(PROVIDER_AUTH_ERROR_EVENT, listener);

      service.scheduleNextToken(300);
      await vi.advanceTimersByTimeAsync(240_000 + 5_000);

      document.removeEventListener(PROVIDER_AUTH_ERROR_EVENT, listener);
      expect(fetchMock).toHaveBeenCalledOnce();
      expect(listener).toHaveBeenCalledOnce();
    });

    it('does not create a token after being destroyed', async () => {
      fetchMock.mockResolvedValue(tokenResponse('second'));

      service.scheduleNextToken(300);
      service.destroy();
      await vi.advanceTimersByTimeAsync(240_000);

      expect(fetchMock).not.toHaveBeenCalled();
    });
  });
});
