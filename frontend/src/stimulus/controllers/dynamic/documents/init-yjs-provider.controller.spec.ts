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

import { type Mock, vi } from 'vitest';

import { LiveCollaborationManager } from 'core-stimulus/helpers/live-collaboration-helpers';
import { PROVIDER_AUTH_ERROR_EVENT } from 'core-stimulus/services/documents/collaboration-token.service';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type InitYjsProviderControllerType from './init-yjs-provider.controller';

const TOKEN_URL = '/api/v3/documents/1/collaboration_token';
const DOCUMENT_NAME = 'http://localhost/api/v3/documents/1';

function stubResponse(status:number, body:unknown):Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    statusText: '',
    json: () => Promise.resolve(body),
  } as Response;
}

function tokenResponse(token:string):Response {
  return stubResponse(201, { token, documentName: DOCUMENT_NAME, expiresAt: '2026-01-01T00:05:00Z', expiresInSeconds: 300 });
}

describe('documents--init-yjs-provider controller', () => {
  let ctx:StimulusTestContext;
  let InitYjsProviderController:typeof InitYjsProviderControllerType;
  let fetchMock:Mock;
  let getToken:() => Promise<string>;
  let sendToken:Mock;

  function requestBody(call:number):unknown {
    const [, init] = fetchMock.mock.calls[call] as [string, RequestInit];
    return JSON.parse(init.body as string);
  }

  beforeAll(async () => {
    ({ default: InitYjsProviderController } = await import('./init-yjs-provider.controller'));
  });

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    fetchMock = vi.spyOn(window, 'fetch');

    ctx = await setupStimulusTest({
      controllers: { 'documents--init-yjs-provider': InitYjsProviderController },
    });
    await ctx.mount(`
      <div data-controller="documents--init-yjs-provider"
           data-documents--init-yjs-provider-hocuspocus-url-value="ws://127.0.0.1:9"
           data-documents--init-yjs-provider-document-name-value="${DOCUMENT_NAME}"
           data-documents--init-yjs-provider-collaboration-token-url-value="${TOKEN_URL}">
      </div>
    `);

    const controller = ctx.getController<InitYjsProviderControllerType>('documents--init-yjs-provider');
    getToken = (controller as unknown as { getToken:() => Promise<string> }).getToken;
    const { provider } = LiveCollaborationManager.getCurrentSessionFor(DOCUMENT_NAME)!;
    sendToken = vi.spyOn(provider, 'sendToken').mockResolvedValue(undefined);
  });

  afterEach(() => {
    ctx.dispose();
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('creates the first token without a previous token', async () => {
    fetchMock.mockResolvedValue(tokenResponse('first'));

    await expect(getToken()).resolves.toBe('first');

    expect(fetchMock).toHaveBeenCalledOnce();
    expect(fetchMock.mock.calls[0][0]).toBe(TOKEN_URL);
    expect(requestBody(0)).toEqual({});
  });

  it('hands the scheduled token over to the provider without another request', async () => {
    fetchMock
      .mockResolvedValueOnce(tokenResponse('first'))
      .mockResolvedValueOnce(tokenResponse('second'));
    await getToken();

    await vi.advanceTimersByTimeAsync(240_000);

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(requestBody(1)).toEqual({ token: 'first' });
    expect(sendToken).toHaveBeenCalledOnce();

    await expect(getToken()).resolves.toBe('second');
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('sends the current token when creating a token on reconnect', async () => {
    fetchMock
      .mockResolvedValueOnce(tokenResponse('first'))
      .mockResolvedValueOnce(tokenResponse('second'));
    await getToken();

    await expect(getToken()).resolves.toBe('second');

    expect(requestBody(1)).toEqual({ token: 'first' });
  });

  it('emits a token_request error when the first token cannot be created', async () => {
    fetchMock.mockResolvedValue(stubResponse(403, {}));
    const listener = vi.fn();
    document.addEventListener(PROVIDER_AUTH_ERROR_EVENT, listener);

    await expect(getToken()).rejects.toThrow('Forbidden');

    document.removeEventListener(PROVIDER_AUTH_ERROR_EVENT, listener);
    expect(listener).toHaveBeenCalledOnce();
    expect((listener.mock.calls[0][0] as CustomEvent).detail).toMatchObject({ kind: 'token_request' });
  });
});
