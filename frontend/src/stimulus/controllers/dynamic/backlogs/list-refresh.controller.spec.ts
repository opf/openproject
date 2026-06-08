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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { waitFor } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type ListRefreshControllerType from './list-refresh.controller';

interface HalEvent {
  eventType:string;
}

describe('Backlogs list-refresh controller', () => {
  let ctx:StimulusTestContext;
  let ListRefreshController:typeof ListRefreshControllerType;
  let events$:Subject<HalEvent[]>;
  let aggregated$:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: ListRefreshController } = await import('./list-refresh.controller'));
  });

  beforeEach(async () => {
    events$ = new Subject<HalEvent[]>();
    aggregated$ = vi.fn().mockReturnValue(events$.asObservable());

    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({ services: { halEvents: { aggregated$ } } }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: {
        'backlogs--list-refresh': ListRefreshController,
      },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  // Mounts the frame and waits for the controller's async connect() to subscribe.
  async function renderFrame() {
    await ctx.mount('<turbo-frame id="backlogs-list" data-controller="backlogs--list-refresh"></turbo-frame>');
    const frame = ctx.container.querySelector<HTMLElement>('[data-controller="backlogs--list-refresh"]')!;
    const reload = vi.fn();
    (frame as unknown as { reload:() => void }).reload = reload;

    // connect() resolves getPluginContext() asynchronously before subscribing.
    await waitFor(() => { expect(aggregated$).toHaveBeenCalledWith('WorkPackage'); });

    return { frame, reload };
  }

  it('subscribes to aggregated WorkPackage events', async () => {
    await renderFrame();

    expect(aggregated$).toHaveBeenCalledWith('WorkPackage');
  });

  it('reloads the frame when an aggregated updated event arrives', async () => {
    const { reload } = await renderFrame();

    events$.next([{ eventType: 'updated' }]);

    expect(reload).toHaveBeenCalledTimes(1);
  });

  it('ignores aggregated events without an updated entry', async () => {
    const { reload } = await renderFrame();

    events$.next([{ eventType: 'created' }, { eventType: 'removed' }]);

    expect(reload).not.toHaveBeenCalled();
  });

  it('stops reloading after the controller disconnects', async () => {
    const { frame, reload } = await renderFrame();

    frame.remove();
    await ctx.nextFrame();

    events$.next([{ eventType: 'updated' }]);

    expect(reload).not.toHaveBeenCalled();
  });

  it('does not subscribe when disconnected before plugin context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    const contextPromise = new Promise((resolve) => { resolveContext = resolve; });

    window.OpenProject = {
      getPluginContext: () => contextPromise,
    } as unknown as typeof window.OpenProject;

    await ctx.mount('<turbo-frame id="backlogs-list" data-controller="backlogs--list-refresh"></turbo-frame>');
    const frame = ctx.container.querySelector<HTMLElement>('[data-controller="backlogs--list-refresh"]')!;
    const reload = vi.fn();
    (frame as unknown as { reload:() => void }).reload = reload;

    frame.remove();
    await ctx.nextFrame();

    resolveContext({ services: { halEvents: { aggregated$ } } });
    await ctx.nextFrame();

    expect(aggregated$).not.toHaveBeenCalled();

    events$.next([{ eventType: 'updated' }]);

    expect(reload).not.toHaveBeenCalled();
  });

  it('ignores stale connect promises after the frame reconnects', async () => {
    let resolveFirstContext!:(context:unknown) => void;
    let resolveSecondContext!:(context:unknown) => void;
    const firstContextPromise = new Promise((resolve) => { resolveFirstContext = resolve; });
    const secondContextPromise = new Promise((resolve) => { resolveSecondContext = resolve; });
    const getPluginContext = vi.fn()
      .mockReturnValueOnce(firstContextPromise)
      .mockReturnValueOnce(secondContextPromise);

    window.OpenProject = {
      getPluginContext,
    } as unknown as typeof window.OpenProject;

    await ctx.mount('<turbo-frame id="backlogs-list" data-controller="backlogs--list-refresh"></turbo-frame>');
    const frame = ctx.container.querySelector<HTMLElement>('[data-controller="backlogs--list-refresh"]')!;
    const reload = vi.fn();
    (frame as unknown as { reload:() => void }).reload = reload;

    await waitFor(() => { expect(getPluginContext).toHaveBeenCalledTimes(1); });

    frame.remove();
    await ctx.nextFrame();
    ctx.container.append(frame);
    await waitFor(() => { expect(getPluginContext).toHaveBeenCalledTimes(2); });

    resolveSecondContext({ services: { halEvents: { aggregated$ } } });
    await waitFor(() => { expect(aggregated$).toHaveBeenCalledTimes(1); });

    resolveFirstContext({ services: { halEvents: { aggregated$ } } });
    await ctx.nextFrame();

    expect(aggregated$).toHaveBeenCalledTimes(1);

    events$.next([{ eventType: 'updated' }]);

    expect(reload).toHaveBeenCalledTimes(1);
  });
});
