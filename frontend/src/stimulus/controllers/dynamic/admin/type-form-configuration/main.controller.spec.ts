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

import { ApplicationInitStatus } from '@angular/core';
import { fireEvent, waitFor } from '@testing-library/dom';
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
  let initializeConfiguration:Mock;
  let fetchConfiguration:Mock;
  let applicationInitStatus:{ donePromise:Promise<void> };
  let getService:Mock;
  let addError:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: TypeFormConfigurationController } = await import('./main.controller'));
  });

  beforeEach(async () => {
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    show = vi.fn();
    initializeConfiguration = vi.fn().mockResolvedValue(undefined);
    fetchConfiguration = vi.fn().mockResolvedValue({});
    applicationInitStatus = { donePromise: Promise.resolve() };
    getService = vi.fn().mockReturnValue(applicationInitStatus);
    addError = vi.fn();
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        injector: { get: getService },
        services: {
          notifications: { addError },
          configurationService: { initialize: initializeConfiguration },
          apiV3Service: { configuration: { get: fetchConfiguration } },
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

  const updateQueryUrl = '/types/1/form_configuration/group/update_query?key=b%29+%3E+10.000+%2F+20.000+Nutzende';

  const savedGroup = `
    <div data-group-key="b) > 10.000 / 20.000 Nutzende"
         data-group-query='{"filters":[]}'
         data-update-query-url="${updateQueryUrl}">
      <button type="button" data-action="click->admin--type-form-configuration--main#editQuery">Edit query</button>
    </div>
  `;

  const temporaryGroup = `
    <div data-group-key="__new_form_configuration_group__"
         data-group-query='{"filters":[]}'
         data-group-temporary="true">
      <label>Section name <input type="text" name="group[name]" value=""></label>
      <button type="button" data-action="click->admin--type-form-configuration--main#editQuery">Edit query</button>
    </div>
  `;

  async function renderConfiguration(group = savedGroup) {
    await ctx.mount(`
      <div data-controller="admin--type-form-configuration--main"
           data-admin--type-form-configuration--main-add-group-url-value="/types/1/form_configuration/group/add_group"
           data-admin--type-form-configuration--main-no-filter-query-value="{}">
        <div data-admin--type-form-configuration--main-target="groupsContainer">
          ${group}
        </div>
      </div>
    `);
    return ctx.getController<TypeFormConfigurationControllerType>('admin--type-form-configuration--main');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderConfiguration();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
    });
  });

  it('waits for Angular initialization before opening the query editor', async () => {
    let resolveConfiguration!:() => void;
    applicationInitStatus.donePromise = new Promise<void>((resolve) => {
      resolveConfiguration = resolve;
    });
    const controller = await renderConfiguration();
    controller.addQueryGroup(new CustomEvent('click'));
    await waitFor(() => expect(getService).toHaveBeenCalledWith(ApplicationInitStatus));
    expect(show).not.toHaveBeenCalled();
    resolveConfiguration();
    await waitFor(() => expect(show).toHaveBeenCalled());
  });

  it('opens the editor repeatedly without refetching the configuration', async () => {
    const controller = await renderConfiguration();

    controller.addQueryGroup(new CustomEvent('click'));
    await waitFor(() => expect(show).toHaveBeenCalledTimes(1));
    ctx.screen.getByRole('button', { name: 'Edit query' }).click();
    await waitFor(() => expect(show).toHaveBeenCalledTimes(2));

    expect(getService.mock.calls).toEqual([[ApplicationInitStatus], [ApplicationInitStatus]]);
    expect(initializeConfiguration).not.toHaveBeenCalled();
    expect(fetchConfiguration).not.toHaveBeenCalled();
    expect(request).not.toHaveBeenCalled();
  });

  it.each(['add', 'edit'])('shows initialization errors when trying to %s a query', async (action) => {
    let rejectInitialization!:(error:Error) => void;
    applicationInitStatus.donePromise = new Promise<void>((_resolve, reject) => {
      rejectInitialization = reject;
    });
    const controller = await renderConfiguration();

    if (action === 'add') {
      controller.addQueryGroup(new CustomEvent('click'));
    } else {
      ctx.screen.getByRole('button', { name: 'Edit query' }).click();
    }
    await waitFor(() => expect(getService).toHaveBeenCalledWith(ApplicationInitStatus));
    const error = new Error('Configuration failed');
    rejectInitialization(error);

    await waitFor(() => expect(addError).toHaveBeenCalledWith(error));
    expect(show).not.toHaveBeenCalled();
  });

  it('shows modal opening errors', async () => {
    const error = new Error('Modal failed');
    show.mockImplementation(() => { throw error; });
    const controller = await renderConfiguration();

    controller.addQueryGroup(new CustomEvent('click'));

    await waitFor(() => expect(addError).toHaveBeenCalledWith(error));
  });

  it('does not open after disconnecting while Angular initializes', async () => {
    let resolveInitialization!:() => void;
    applicationInitStatus.donePromise = new Promise<void>((resolve) => { resolveInitialization = resolve; });
    const controller = await renderConfiguration();
    controller.addQueryGroup(new CustomEvent('click'));
    await waitFor(() => expect(getService).toHaveBeenCalledWith(ApplicationInitStatus));

    controller.element.remove();
    resolveInitialization();
    await ctx.nextFrame();

    expect(show).not.toHaveBeenCalled();
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
        '/types/1/form_configuration/group/add_group',
        expect.objectContaining({ method: 'POST' }),
      );
    });
    const body = (request.mock.calls[0][1] as { body:URLSearchParams }).body;
    expect(body.get('group_type')).toBe('query');
    expect(body.get('query')).toBe(JSON.stringify({ filters: [] }));
  });

  it('patches the query to the URL rendered on the group instead of building one from the key', async () => {
    await renderConfiguration();

    ctx.screen.getByRole('button', { name: 'Edit query' }).click();

    await waitFor(() => {
      expect(show).toHaveBeenCalled();
    });

    const config = show.mock.calls[0][0] as QueryEditorConfig;
    expect(config.currentQuery).toEqual({ filters: [] });

    config.callback({ filters: [{ project: { operator: '=', values: ['1'] } }] });

    await waitFor(() => {
      expect(request).toHaveBeenCalledWith(
        updateQueryUrl,
        expect.objectContaining({ method: 'PATCH' }),
      );
    });
  });

  it('rerenders a temporary group with its edited query and current name', async () => {
    await renderConfiguration(temporaryGroup);
    fireEvent.input(ctx.screen.getByRole('textbox', { name: 'Section name' }), { target: { value: 'Draft children' } });

    ctx.screen.getByRole('button', { name: 'Edit query' }).click();
    await waitFor(() => expect(show).toHaveBeenCalledTimes(1));
    const query = { highlightingMode: 'none' };
    (show.mock.calls[0][0] as QueryEditorConfig).callback(query);

    await waitFor(() => expect(request).toHaveBeenCalledWith(
      '/types/1/form_configuration/group/add_group',
      expect.objectContaining({ method: 'POST' }),
    ));
    const body = (request.mock.calls[0][1] as { body:URLSearchParams }).body;
    expect(body.get('name')).toBe('Draft children');
    expect(body.get('query')).toBe(JSON.stringify(query));
    expect(body.get('group_type')).toBe('query');
  });

  it('uses authoritative server props when reopening the replaced group', async () => {
    await renderConfiguration();
    const original = ctx.container.querySelector<HTMLElement>('[data-group-key]')!;
    const serverProps = { columns: ['subject'] };
    request.mockImplementation(() => {
      const replacement = original.cloneNode(true) as HTMLElement;
      replacement.dataset.groupQuery = JSON.stringify(serverProps);
      original.replaceWith(replacement);
      return Promise.resolve({ html: '', headers: new Headers() });
    });

    ctx.screen.getByRole('button', { name: 'Edit query' }).click();
    await waitFor(() => expect(show).toHaveBeenCalledTimes(1));
    (show.mock.calls[0][0] as QueryEditorConfig).callback({ columns: ['id', 'subject'] });
    await waitFor(() => expect(original).not.toBeInTheDocument());
    await ctx.nextFrame();
    ctx.screen.getByRole('button', { name: 'Edit query' }).click();
    await waitFor(() => expect(show).toHaveBeenCalledTimes(2));
    expect((show.mock.calls[1][0] as QueryEditorConfig).currentQuery).toEqual(serverProps);
    expect(original).toHaveAttribute('data-group-query', '{"filters":[]}');
  });

  it('retains saved props after a rejected save', async () => {
    await renderConfiguration();
    const group = ctx.container.querySelector<HTMLElement>('[data-group-key]')!;
    const before = group.innerHTML;
    request.mockRejectedValue(new Error('Save failed'));
    ctx.screen.getByRole('button', { name: 'Edit query' }).click();
    await waitFor(() => expect(show).toHaveBeenCalledTimes(1));
    (show.mock.calls[0][0] as QueryEditorConfig).callback({ columns: ['subject'] });
    await waitFor(() => expect(request).toHaveBeenCalledTimes(1));
    await ctx.nextFrame();
    expect(group).toHaveAttribute('data-group-query', '{"filters":[]}');
    expect(group.innerHTML).toBe(before);
  });

  it('warns instead of posting when the group carries no update-query URL', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    await renderConfiguration();
    const group = ctx.container.querySelector<HTMLElement>('[data-group-key]')!;
    delete group.dataset.updateQueryUrl;

    ctx.screen.getByRole('button', { name: 'Edit query' }).click();

    await waitFor(() => {
      expect(show).toHaveBeenCalled();
    });

    (show.mock.calls[0][0] as QueryEditorConfig).callback({ filters: [] });
    await ctx.nextFrame();

    expect(warn).toHaveBeenCalledWith(expect.stringContaining('data-update-query-url'), group);
    expect(request).not.toHaveBeenCalled();
  });

  it('does not open the query editor when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderConfiguration();

    controller.addQueryGroup(new CustomEvent('click'));
    await ctx.nextFrame();

    controller.element.remove();
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
