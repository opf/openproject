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

import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { Controller } from '@hotwired/stimulus';
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
  const filterLists = vi.fn();

  class FilterListStub extends Controller {
    filterLists = filterLists;
  }

  beforeAll(async () => {
    ({ default: TypeFormConfigurationController } = await import('./main.controller'));
  });

  beforeEach(async () => {
    filterLists.mockClear();
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
      controllers: {
        'admin--type-form-configuration--main': TypeFormConfigurationController,
        'filter--filter-list': FilterListStub,
      },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  const updateQueryUrl = '/types/1/form_configuration/group/update_query?key=b%29+%3E+10.000+%2F+20.000+Nutzende';

  async function renderConfiguration() {
    await ctx.mount(`
      <div data-controller="admin--type-form-configuration--main"
           data-admin--type-form-configuration--main-add-group-url-value="/types/1/form_configuration/group/add_group"
           data-admin--type-form-configuration--main-no-filter-query-value="{}">
        <div data-admin--type-form-configuration--main-target="groupsContainer">
          <div data-group-key="b) > 10.000 / 20.000 Nutzende"
               data-group-query='{"filters":[]}'
               data-update-query-url="${updateQueryUrl}">
            <button type="button" data-test-selector="edit-query">Edit query</button>
          </div>
        </div>
      </div>
    `);
    return ctx.getController<TypeFormConfigurationControllerType>('admin--type-form-configuration--main');
  }

  async function renderEditor({ editing = false } = {}) {
    await ctx.mount(`
      <section aria-label="Form editor"
               data-controller="admin--type-form-configuration--main"
               data-action="sortable-lists:before-move->admin--type-form-configuration--main#confirmDiscardingEdit turbo:morph-element->admin--type-form-configuration--main#reapplyInactiveFilter"
               data-admin--type-form-configuration--main-add-group-url-value="/forms/1/group/add_group"
               data-admin--type-form-configuration--main-no-filter-query-value="{}">
        <div data-controller="filter--filter-list"></div>
        <div data-admin--type-form-configuration--main-target="inactiveContainer">
          <ul aria-label="Inactive attributes"><li>Assignee</li></ul>
        </div>
        <div data-admin--type-form-configuration--main-target="groupsContainer">
          <section aria-label="Details" ${editing ? 'data-edit-mode="true"' : ''}></section>
        </div>
      </section>
    `);
    return within(screen.getByRole('region', { name: 'Form editor' }));
  }

  function fireBeforeMove(element:HTMLElement) {
    return fireEvent(element, new CustomEvent('sortable-lists:before-move', { bubbles: true, cancelable: true }));
  }

  function fireMorph(element:HTMLElement) {
    return fireEvent(element, new CustomEvent('turbo:morph-element', { bubbles: true }));
  }

  describe('confirming a move while a group editor is open', () => {
    it('does not ask when no editor is open', async () => {
      const editor = await renderEditor();
      const confirm = vi.spyOn(window, 'confirm');

      expect(fireBeforeMove(editor.getByRole('list'))).toBe(true);
      expect(confirm).not.toHaveBeenCalled();
    });

    it('cancels the move when the user declines', async () => {
      const editor = await renderEditor({ editing: true });
      vi.spyOn(window, 'confirm').mockReturnValue(false);

      expect(fireBeforeMove(editor.getByRole('list'))).toBe(false);
    });

    it('lets the move proceed when the user accepts', async () => {
      const editor = await renderEditor({ editing: true });
      const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true);

      expect(fireBeforeMove(editor.getByRole('list'))).toBe(true);
      expect(confirm).toHaveBeenCalledOnce();
    });
  });

  describe('keeping the inactive filter applied across morphs', () => {
    it('re-applies the filter once after the inactive list was morphed', async () => {
      const editor = await renderEditor();
      filterLists.mockClear();
      const row = editor.getByText('Assignee');

      fireMorph(row);
      fireMorph(row);

      await waitFor(() => expect(filterLists).toHaveBeenCalledOnce());
      await ctx.nextFrame();
      expect(filterLists).toHaveBeenCalledOnce();
    });

    it('ignores morphs outside the inactive list', async () => {
      const editor = await renderEditor();
      filterLists.mockClear();

      fireMorph(editor.getByRole('region', { name: 'Details' }));
      await ctx.nextFrame();

      expect(filterLists).not.toHaveBeenCalled();
    });
  });

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
        '/types/1/form_configuration/group/add_group',
        expect.objectContaining({ method: 'POST' }),
      );
    });
    const body = (request.mock.calls[0][1] as { body:URLSearchParams }).body;
    expect(body.get('group_type')).toBe('query');
    expect(body.get('query')).toBe(JSON.stringify({ filters: [] }));
  });

  it('patches the query to the URL rendered on the group instead of building one from the key', async () => {
    const controller = await renderConfiguration();
    const button = document.querySelector<HTMLButtonElement>('[data-test-selector="edit-query"]')!;

    controller.editQuery({ preventDefault: vi.fn(), currentTarget: button } as unknown as Event);

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

  it('warns instead of posting when the group carries no update-query URL', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const controller = await renderConfiguration();
    const group = document.querySelector<HTMLElement>('[data-group-key]')!;
    delete group.dataset.updateQueryUrl;
    const button = document.querySelector<HTMLButtonElement>('[data-test-selector="edit-query"]')!;

    controller.editQuery({ preventDefault: vi.fn(), currentTarget: button } as unknown as Event);

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
