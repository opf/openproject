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
import type LazyPageControllerType from './lazy-page.controller';
import type IndexController from './index.controller';

describe('Activities tab lazy page controller', () => {
  let ctx:StimulusTestContext;
  let LazyPageController:typeof LazyPageControllerType;
  let requestStream:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: LazyPageController } = await import('./lazy-page.controller'));
  });

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });

    requestStream = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({ services: { turboRequests: { requestStream } } }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'work-packages--activities-tab--lazy-page': LazyPageController },
    });
  });

  afterEach(() => {
    vi.useRealTimers();
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderPage() {
    await ctx.mount(`
      <div data-controller="work-packages--activities-tab--lazy-page"
           data-work-packages--activities-tab--lazy-page-url-value="/work_packages/1/activities/page"
           data-work-packages--activities-tab--lazy-page-page-value="2"></div>
    `);
    const controller = ctx.getController<LazyPageControllerType>('work-packages--activities-tab--lazy-page');
    // The index outlet lives outside this fixture; stub the part the URL
    // builder reads.
    controller.indexOutlet = { filterValue: 'all' } as unknown as IndexController;
    return controller;
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderPage();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { requestStream },
    });
  });

  it('loads the page stream after appearing in the viewport', async () => {
    const controller = await renderPage();

    controller.appear();
    await vi.advanceTimersByTimeAsync(300);

    // The intersection observer can fire appear() a second time, so only the
    // request URL is asserted.
    expect(requestStream).toHaveBeenCalled();
    const url = requestStream.mock.calls[0][0] as string;
    expect(url).toContain('/work_packages/1/activities/page');
    expect(url).toContain('page=2');
    expect(url).toContain('filter=all');
  });

  it('does not load when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderPage();
    const root = ctx.container.querySelector('[data-controller="work-packages--activities-tab--lazy-page"]')!;

    controller.appear();
    await vi.advanceTimersByTimeAsync(300);

    root.remove();
    await ctx.nextFrame();

    resolveContext({ services: { turboRequests: { requestStream } } });
    await ctx.nextFrame();

    expect(requestStream).not.toHaveBeenCalled();
  });
});
