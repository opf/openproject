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

import { HocuspocusProviderWebsocket, type HocuspocusProvider } from '@hocuspocus/provider';
import { vi } from 'vitest';
import { LiveCollaborationManager } from 'core-stimulus/helpers/live-collaboration-helpers';
import { DocumentCache } from 'core-stimulus/services/documents/document-cache.service';
import {
  PROVIDER_AUTH_ERROR_EVENT,
  RefreshError,
  TokenRefreshService,
} from 'core-stimulus/services/documents/token-refresh.service';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import InitYjsProviderController from './init-yjs-provider.controller';

describe('InitYjsProviderController token denial', () => {
  let ctx:StimulusTestContext;
  let cache:{ evict:ReturnType<typeof vi.fn>; close:ReturnType<typeof vi.fn> };
  let provider:HocuspocusProvider;
  let authErrors:CustomEvent<{ kind:string }>[];
  let originalOpenProject:typeof window.OpenProject;

  const recordAuthError = (event:Event) => authErrors.push(event as CustomEvent<{ kind:string }>);

  beforeEach(async () => {
    authErrors = [];
    cache = { evict: vi.fn().mockResolvedValue(undefined), close: vi.fn() };
    document.addEventListener(PROVIDER_AUTH_ERROR_EVENT, recordAuthError);

    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: { pathHelperService: { loginPath: () => '/op/login' } },
      }),
    } as unknown as typeof window.OpenProject;

    vi.spyOn(DocumentCache, 'open').mockResolvedValue(cache as unknown as DocumentCache);
    vi.spyOn(HocuspocusProviderWebsocket.prototype, 'connect').mockResolvedValue(undefined);
    const initialize = vi.spyOn(LiveCollaborationManager, 'initializeYjsProvider');

    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    ctx = await setupStimulusTest({ controllers: { 'init-yjs-provider': InitYjsProviderController } });
    await ctx.mount(`
      <div data-controller="init-yjs-provider"
           data-init-yjs-provider-hocuspocus-url-value="ws://collab.test"
           data-init-yjs-provider-token-payload-value="initial-token"
           data-init-yjs-provider-document-name-value="document-1"
           data-init-yjs-provider-token-expires-in-seconds-value="10"
           data-init-yjs-provider-refresh-url-value="/documents/1/refresh_token"></div>
    `);
    await ctx.nextFrame();

    provider = initialize.mock.calls[0][0];
  });

  afterEach(() => {
    try {
      ctx.dispose();
    } finally {
      document.removeEventListener(PROVIDER_AUTH_ERROR_EVENT, recordAuthError);
      vi.useRealTimers();
      vi.restoreAllMocks();
      window.OpenProject = originalOpenProject;
    }
  });

  it('evicts the offline copy and announces the denial once, and refuses later token requests', async () => {
    const fetchToken = vi.spyOn(TokenRefreshService, 'fetchToken').mockRejectedValue(new RefreshError('access_denied', 'HTTP 403', 403));

    await vi.advanceTimersByTimeAsync(8000);

    expect(fetchToken).toHaveBeenCalledWith('/documents/1/refresh_token', '/op/login');
    expect(cache.evict).toHaveBeenCalledOnce();
    expect(authErrors.map((event) => event.detail.kind)).toEqual(['access_denied']);

    const requestToken = provider.configuration.token as () => Promise<string>;
    await expect(requestToken()).rejects.toMatchObject({ kind: 'access_denied' });

    expect(cache.evict).toHaveBeenCalledOnce();
    expect(authErrors).toHaveLength(1);
  });

  it('opens nothing while waiting for the app services, so a disconnect cannot leave the offline copy open', async () => {
    let resolveContext:(context:unknown) => void = () => {};
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;
    const open = vi.spyOn(DocumentCache, 'open').mockClear();
    const initialize = vi.spyOn(LiveCollaborationManager, 'initializeYjsProvider').mockClear();

    await ctx.mount(`
      <div id="pending-editor"
           data-controller="init-yjs-provider"
           data-init-yjs-provider-hocuspocus-url-value="ws://collab.test"
           data-init-yjs-provider-token-payload-value="initial-token"
           data-init-yjs-provider-document-name-value="document-2"
           data-init-yjs-provider-token-expires-in-seconds-value="10"
           data-init-yjs-provider-refresh-url-value="/documents/2/refresh_token"></div>
    `);

    ctx.container.querySelector('#pending-editor')!.remove();
    await ctx.nextFrame();

    resolveContext({ services: { pathHelperService: { loginPath: () => '/op/login' } } });
    await ctx.nextFrame();

    expect(open).not.toHaveBeenCalled();
    expect(initialize).not.toHaveBeenCalled();
  });
});
