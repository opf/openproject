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
import type TypeFormConfigurationControllerType from './main.controller';

interface QueryEditorConfig {
  currentQuery:unknown;
  callback:(queryProps:unknown) => void;
  disabledTabs:Record<string, string>;
}

describe('Type form configuration controller', () => {
  let ctx:StimulusTestContext;
  let TypeFormConfigurationController:typeof TypeFormConfigurationControllerType;
  let request:Mock;
  let show:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: TypeFormConfigurationController } = await import('./main.controller'));
  });

  beforeEach(async () => {
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    show = vi.fn();
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: {
          turboRequests: { request },
          externalRelationQueryConfiguration: { show },
        },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'admin--type-form-configuration--main': TypeFormConfigurationController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderConfiguration() {
    await ctx.mount(`
      <div data-controller="admin--type-form-configuration--main"
           data-admin--type-form-configuration--main-add-group-url-value="/types/1/form_configuration/groups"
           data-admin--type-form-configuration--main-no-filter-query-value="{}"
           data-admin--type-form-configuration--main-groups-url-value="/types/1/form_configuration/groups">
        <div data-admin--type-form-configuration--main-target="groupsContainer"></div>
      </div>
    `);
    return ctx.getController<TypeFormConfigurationControllerType>('admin--type-form-configuration--main');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderConfiguration();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
      externalRelationQueryConfiguration: { show },
    });
  });

  it('opens the query editor and posts the new group from its callback', async () => {
    const controller = await renderConfiguration();

    controller.addQueryGroup(new CustomEvent('click'));

    await waitFor(() => {
      expect(show).toHaveBeenCalled();
    });

    const config = show.mock.calls[0][0] as QueryEditorConfig;
    expect(config.currentQuery).toEqual({});

    config.callback({ filters: [] });

    await waitFor(() => {
      expect(request).toHaveBeenCalledWith(
        '/types/1/form_configuration/groups',
        expect.objectContaining({ method: 'POST' }),
      );
    });
    const body = (request.mock.calls[0][1] as { body:URLSearchParams }).body;
    expect(body.get('group_type')).toBe('query');
    expect(body.get('query')).toBe(JSON.stringify({ filters: [] }));
  });

  it('does not open the query editor when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderConfiguration();
    const root = ctx.container.querySelector('[data-controller="admin--type-form-configuration--main"]')!;

    controller.addQueryGroup(new CustomEvent('click'));
    await ctx.nextFrame();

    root.remove();
    await ctx.nextFrame();

    resolveContext({
      services: {
        turboRequests: { request },
        externalRelationQueryConfiguration: { show },
      },
    });
    await ctx.nextFrame();

    expect(show).not.toHaveBeenCalled();
  });
});
