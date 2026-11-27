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

import { HocuspocusProvider } from '@hocuspocus/provider';
import { act, renderHook } from '@testing-library/react';
import {
  PROVIDER_AUTH_ERROR_EVENT,
  ProviderAuthErrorKind,
} from 'core-stimulus/services/documents/token-refresh.service';
import * as Y from 'yjs';
import { useCollaboration } from './useCollaboration';

type Listener = () => void;

class FakeProvider {
  synced = false;
  document = new Y.Doc();
  private listeners = new Map<string, Set<Listener>>();

  on(event:string, listener:Listener) {
    const registered = this.listeners.get(event) ?? new Set<Listener>();
    registered.add(listener);
    this.listeners.set(event, registered);
  }

  off(event:string, listener:Listener) {
    this.listeners.get(event)?.delete(listener);
  }

  emit(event:string) {
    if (event === 'synced') {
      if (this.synced) {
        return;
      }

      this.synced = true;
    }

    if (event === 'disconnect') {
      this.synced = false;
    }

    this.listeners.get(event)?.forEach((listener) => listener());
  }
}

function dispatchAuthError(kind:ProviderAuthErrorKind) {
  document.dispatchEvent(new CustomEvent(PROVIDER_AUTH_ERROR_EVENT, { detail: { kind, message: 'test' } }));
}

describe('useCollaboration', () => {
  let provider:FakeProvider;

  const render = () => renderHook(() => useCollaboration(provider as unknown as HocuspocusProvider));

  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    provider = new FakeProvider();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('keeps an empty but synced document editable (soft offline) after a disconnect', () => {
    const { result } = render();

    act(() => provider.emit('synced'));
    act(() => provider.emit('disconnect'));

    expect(result.current.isLoading).toBe(false);
    expect(result.current.offlineMode).toBe(false);

    act(() => { vi.advanceTimersByTime(4_999); });

    expect(result.current.offlineMode).toBe(false);

    act(() => { vi.advanceTimersByTime(1); });

    expect(result.current.offlineMode).toBe(true);
    expect(result.current.blockingOffline).toBe(false);
    expect(result.current.isLoading).toBe(false);
  });

  it('keeps loading after a disconnect while unverified, then blocks at the initial timeout', () => {
    const { result } = render();

    act(() => { vi.advanceTimersByTime(2_000); });
    act(() => provider.emit('disconnect'));

    expect(result.current.isLoading).toBe(true);

    act(() => { vi.advanceTimersByTime(2_999); });

    expect(result.current.isLoading).toBe(true);
    expect(result.current.offlineMode).toBe(false);

    act(() => { vi.advanceTimersByTime(1); });

    expect(result.current.isLoading).toBe(false);
    expect(result.current.offlineMode).toBe(true);
    expect(result.current.blockingOffline).toBe(true);
  });

  it('is soft offline after the initial timeout when the document was loaded from the cache', () => {
    provider.document.getText('cached').insert(0, 'cached content');

    const { result } = render();

    expect(result.current.isLoading).toBe(true);

    act(() => { vi.advanceTimersByTime(5_000); });

    expect(result.current.isLoading).toBe(false);
    expect(result.current.offlineMode).toBe(true);
    expect(result.current.blockingOffline).toBe(false);
  });

  it('blocks permanently on access denial, even after a later sync', () => {
    const { result } = render();

    act(() => provider.emit('synced'));
    act(() => dispatchAuthError('access_denied'));

    expect(result.current.blockingOffline).toBe(true);

    act(() => provider.emit('disconnect'));
    act(() => provider.emit('synced'));

    expect(result.current.blockingOffline).toBe(true);
    expect(result.current.offlineMode).toBe(true);
  });

  it('goes soft offline at once on a non-terminal auth error and recovers on sync', () => {
    const { result } = render();

    act(() => provider.emit('synced'));
    act(() => dispatchAuthError('token_refresh'));

    expect(result.current.offlineMode).toBe(true);
    expect(result.current.blockingOffline).toBe(false);

    act(() => provider.emit('disconnect'));
    act(() => provider.emit('synced'));

    expect(result.current.offlineMode).toBe(false);
    expect(result.current.blockingOffline).toBe(false);
  });
});
