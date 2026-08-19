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
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type MainMenuControllerType from './main.controller';

describe('Main menu controller', () => {
  let ctx:StimulusTestContext;
  let MainMenuController:typeof MainMenuControllerType;
  let next:Mock;
  let originalOpenProject:typeof window.OpenProject;

  const pluginContext = () => ({
    injector: { get: () => ({ navigationEvents$: { next } }) },
  });

  beforeAll(async () => {
    ({ default: MainMenuController } = await import('./main.controller'));
  });

  beforeEach(async () => {
    next = vi.fn();
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve(pluginContext()),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'menus--main': MainMenuController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderMenu() {
    await ctx.mount(`
      <div data-controller="menus--main">
        <div data-menus--main-target="sidebar"></div>
        <ul data-menus--main-target="root">
          <li data-name="overview" class="open"><a class="toggler">Overview</a></li>
        </ul>
      </div>
    `);
    return ctx.getController<MainMenuControllerType>('menus--main');
  }

  it('exposes the full plugin context as a promise', async () => {
    const controller = await renderMenu();

    await expect(controller.pluginContext).resolves.toMatchObject({
      injector: expect.anything() as unknown,
    });
  });

  it('publishes the active menu entry on initialize', async () => {
    await renderMenu();

    await waitFor(() => {
      expect(next).toHaveBeenCalledWith('overview');
    });
  });

  it('publishes nothing when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    await renderMenu();
    const root = ctx.container.querySelector('[data-controller="menus--main"]')!;

    root.remove();
    await ctx.nextFrame();

    resolveContext(pluginContext());
    await ctx.nextFrame();

    expect(next).not.toHaveBeenCalled();
  });
});
