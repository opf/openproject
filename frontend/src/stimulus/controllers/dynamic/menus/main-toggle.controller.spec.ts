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
import type MainToggleControllerType from './main-toggle.controller';

describe('Main menu toggle controller', () => {
  let ctx:StimulusTestContext;
  let MainToggleController:typeof MainToggleControllerType;
  let initializeMenu:Mock;
  let toggleNavigation:Mock;
  let originalOpenProject:typeof window.OpenProject;

  const pluginContext = () => ({
    injector: { get: () => ({ initializeMenu, toggleNavigation }) },
  });

  beforeAll(async () => {
    ({ default: MainToggleController } = await import('./main-toggle.controller'));
  });

  beforeEach(async () => {
    initializeMenu = vi.fn();
    toggleNavigation = vi.fn();
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve(pluginContext()),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'menus--main-toggle': MainToggleController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderToggle() {
    await ctx.mount('<button data-controller="menus--main-toggle"></button>');
    return ctx.getController<MainToggleControllerType>('menus--main-toggle');
  }

  it('initializes the menu service after connect', async () => {
    await renderToggle();

    await waitFor(() => {
      expect(initializeMenu).toHaveBeenCalledTimes(1);
    });
  });

  it('delegates navigation toggles to the menu service', async () => {
    const controller = await renderToggle();
    await waitFor(() => {
      expect(initializeMenu).toHaveBeenCalled();
    });

    const event = new CustomEvent('click');
    controller.toggleNavigation(event);

    expect(toggleNavigation).toHaveBeenCalledWith(event);
  });

  it('does not initialize the menu when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderToggle();
    const button = ctx.container.querySelector('button')!;

    button.remove();
    await ctx.nextFrame();

    resolveContext(pluginContext());
    await ctx.nextFrame();

    expect(initializeMenu).not.toHaveBeenCalled();
    expect(controller.pluginContext).toBeInstanceOf(Promise);
  });
});
