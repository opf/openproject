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

import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type PollingControllerType from './polling.controller';
import type IndexController from './index.controller';

describe('Activities tab polling controller', () => {
  let ctx:StimulusTestContext;
  let PollingController:typeof PollingControllerType;
  let request:Mock;
  let resolveContext:(context:unknown) => void;
  let originalOpenProject:typeof window.OpenProject;

  const pluginContext = () => ({
    services: { turboRequests: { request }, apiV3Service: {} },
  });

  beforeAll(async () => {
    ({ default: PollingController } = await import('./polling.controller'));
  });

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'setInterval', 'clearInterval'] });

    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    originalOpenProject = window.OpenProject;
    // The outlets must be stubbed before the context resolves, so resolution
    // stays manual in every test. One shared promise serves all accesses.
    const contextPromise = new Promise((resolve) => { resolveContext = resolve; });
    window.OpenProject = {
      getPluginContext: () => contextPromise,
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'work-packages--activities-tab--polling': PollingController },
    });
  });

  afterEach(() => {
    vi.useRealTimers();
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderPolling() {
    await ctx.mount(`
      <div data-controller="work-packages--activities-tab--polling"
           data-work-packages--activities-tab--polling-last-server-timestamp-value="2026-06-11T10:00:00Z"
           data-work-packages--activities-tab--polling-update-streams-path-value="/work_packages/1/activities/update_streams"></div>
    `);
    const controller = ctx.getController<PollingControllerType>('work-packages--activities-tab--polling');

    // The index and sibling outlets live outside this fixture; stub the parts
    // the polling paths read.
    controller.indexOutlet = {
      workPackageIdValue: 1,
      userIdValue: 2,
      sortingValue: 'asc',
      filterValue: 'all',
    } as unknown as IndexController;
    Object.defineProperty(controller, 'workPackagesActivitiesTabAutoScrollingOutlet', {
      value: {
        isJournalsContainerScrolledToBottom: () => false,
        performAutoScrollingOnStreamsUpdate: vi.fn(),
      },
      configurable: true,
    });
    Object.defineProperty(controller, 'workPackagesActivitiesTabStemsOutlet', {
      value: { handleStemVisibility: vi.fn() },
      configurable: true,
    });

    return controller;
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderPolling();

    resolveContext(pluginContext());

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
    });
  });

  it('polls the update streams path once connected', async () => {
    await renderPolling();

    resolveContext(pluginContext());
    await vi.advanceTimersByTimeAsync(10000);

    expect(request).toHaveBeenCalledTimes(1);
    const url = request.mock.calls[0][0] as string;
    expect(url).toContain('/work_packages/1/activities/update_streams');
    expect(url).toContain('sortBy=asc');
    expect(url).toContain('filter=all');
  });

  it('stops polling on disconnect', async () => {
    await renderPolling();
    const root = ctx.container.querySelector('[data-controller="work-packages--activities-tab--polling"]')!;

    resolveContext(pluginContext());
    await vi.advanceTimersByTimeAsync(10000);
    expect(request).toHaveBeenCalledTimes(1);

    root.remove();
    await ctx.nextFrame();
    await vi.advanceTimersByTimeAsync(30000);

    expect(request).toHaveBeenCalledTimes(1);
  });
});
