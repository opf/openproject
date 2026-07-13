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
import { of } from 'rxjs';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type RepositoryNavigationControllerType from './repository-navigation.controller';

describe('Repository navigation controller', () => {
  let ctx:StimulusTestContext;
  let RepositoryNavigationController:typeof RepositoryNavigationControllerType;
  let get:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: RepositoryNavigationController } = await import('./repository-navigation.controller'));
  });

  beforeEach(async () => {
    get = vi.fn().mockReturnValue(of('<div class="loaded-entry"></div>'));
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({ services: { http: { get } } }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'repository-navigation': RepositoryNavigationController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderBrowser() {
    await ctx.mount(`
      <div data-controller="repository-navigation">
        <input data-repository-navigation-target="revision" value="">
        <div data-repository-navigation-target="repoBrowser">
          <a data-element="entry-1" data-url="/repository/dir?path=sub"
             data-action="repository-navigation#toggleDirectory">sub/</a>
          <div id="entry-1"></div>
        </div>
      </div>
    `);
    return ctx.getController<RepositoryNavigationControllerType>('repository-navigation');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderBrowser();

    await expect(controller.services).resolves.toMatchObject({
      http: { get },
    });
  });

  it('loads and expands a directory on toggle', async () => {
    const controller = await renderBrowser();
    const link = ctx.container.querySelector('a')!;
    const content = ctx.container.querySelector<HTMLElement>('#entry-1')!;

    controller.toggleDirectory({ target: link } as unknown as MouseEvent);

    expect(content.classList.contains('loading')).toBe(true);

    await waitFor(() => {
      expect(get).toHaveBeenCalledWith('/repository/dir?path=sub', { responseType: 'text' });
    });
    await waitFor(() => {
      expect(content.classList.contains('open')).toBe(true);
    });
    expect(content.classList.contains('loading')).toBe(false);
    expect(ctx.container.querySelector('.loaded-entry')).not.toBeNull();
  });

  it('does not load when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderBrowser();
    const root = ctx.container.querySelector('[data-controller="repository-navigation"]')!;
    const link = ctx.container.querySelector('a')!;

    controller.toggleDirectory({ target: link } as unknown as MouseEvent);
    await ctx.nextFrame();

    root.remove();
    await ctx.nextFrame();

    resolveContext({ services: { http: { get } } });
    await ctx.nextFrame();

    expect(get).not.toHaveBeenCalled();
  });
});
