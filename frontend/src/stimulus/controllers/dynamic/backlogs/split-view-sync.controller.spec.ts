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

import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type SplitViewSyncControllerType from './split-view-sync.controller';

const MOVED_EVENT = 'op-dispatched:backlogs:work-package-moved';

describe('Backlogs split-view-sync controller', () => {
  let ctx:StimulusTestContext;
  let SplitViewSyncController:typeof SplitViewSyncControllerType;
  let refresh:Mock;
  let id:Mock;
  let hasValue:Mock;
  let state:Mock;
  let getPluginContext:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: SplitViewSyncController } = await import('./split-view-sync.controller'));
  });

  beforeEach(async () => {
    refresh = vi.fn(() => Promise.resolve());
    id = vi.fn(() => ({ refresh }));
    hasValue = vi.fn(() => true);
    state = vi.fn(() => ({ hasValue }));
    getPluginContext = vi.fn(() => Promise.resolve({
      services: { apiV3Service: { work_packages: { id, cache: { state } } } },
    }));

    originalOpenProject = window.OpenProject;
    window.OpenProject = { getPluginContext } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: {
        'backlogs--split-view-sync': SplitViewSyncController,
      },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  // Mounts the controller host and waits for the async service wiring to finish.
  async function renderHost() {
    await ctx.mount(`
      <div data-controller="backlogs--split-view-sync"
           data-action="${MOVED_EVENT}@document->backlogs--split-view-sync#onWorkPackageMoved"></div>
    `);
    const host = ctx.container.querySelector<HTMLElement>('[data-controller="backlogs--split-view-sync"]')!;

    await waitFor(() => { expect(getPluginContext).toHaveBeenCalled(); });
    await ctx.nextFrame();

    return host;
  }

  function dispatchMoved(detail:object) {
    document.dispatchEvent(new CustomEvent(MOVED_EVENT, { detail }));
  }

  it('refreshes the moved work package cache when it is loaded', async () => {
    await renderHost();

    dispatchMoved({ work_package_id: 42 });

    await waitFor(() => {
      expect(state).toHaveBeenCalledWith('42');
      expect(id).toHaveBeenCalledWith('42');
      expect(refresh).toHaveBeenCalled();
    });
  });

  it('does not refresh when the moved work package is not loaded', async () => {
    hasValue.mockReturnValue(false);
    await renderHost();

    dispatchMoved({ work_package_id: 42 });
    await ctx.nextFrame();

    expect(state).toHaveBeenCalledWith('42');
    expect(refresh).not.toHaveBeenCalled();
  });

  it('ignores a work-package-moved event without a work package id', async () => {
    await renderHost();

    dispatchMoved({});
    await ctx.nextFrame();

    expect(refresh).not.toHaveBeenCalled();
  });

  it('ignores the event before the services have resolved', async () => {
    let resolveContext!:(context:unknown) => void;
    const contextPromise = new Promise((resolve) => { resolveContext = resolve; });
    getPluginContext.mockReturnValue(contextPromise);

    await ctx.mount(`
      <div data-controller="backlogs--split-view-sync"
           data-action="${MOVED_EVENT}@document->backlogs--split-view-sync#onWorkPackageMoved"></div>
    `);
    await ctx.nextFrame();

    dispatchMoved({ work_package_id: 42 });
    await ctx.nextFrame();

    expect(refresh).not.toHaveBeenCalled();

    resolveContext({ services: { apiV3Service: { work_packages: { id, cache: { state } } } } });
    await ctx.nextFrame();

    dispatchMoved({ work_package_id: 42 });

    await waitFor(() => { expect(refresh).toHaveBeenCalled(); });
  });

  it('stops refreshing once disconnected', async () => {
    const host = await renderHost();

    host.remove();
    await ctx.nextFrame();

    dispatchMoved({ work_package_id: 42 });
    await ctx.nextFrame();

    expect(refresh).not.toHaveBeenCalled();
  });

  it('refreshes every cached member of a batch event, in order', async () => {
    await renderHost();

    dispatchMoved({ work_package_ids: [11, 12, 13] });

    await waitFor(() => {
      expect(id).toHaveBeenCalledWith('11');
      expect(id).toHaveBeenCalledWith('12');
      expect(id).toHaveBeenCalledWith('13');
      expect(refresh).toHaveBeenCalledTimes(3);
    });
  });

  it('skips uncached members of a batch event', async () => {
    hasValue.mockImplementation(() => state.mock.calls.length === 2);
    await renderHost();

    dispatchMoved({ work_package_ids: [11, 12] });

    await waitFor(() => {
      expect(state).toHaveBeenCalledWith('11');
      expect(state).toHaveBeenCalledWith('12');
      expect(refresh).toHaveBeenCalledTimes(1);
    });
  });

  it('ignores an event with neither id field', async () => {
    await renderHost();

    dispatchMoved({});
    await ctx.nextFrame();

    expect(refresh).not.toHaveBeenCalled();
  });
});
