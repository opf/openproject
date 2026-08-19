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
import type ProjectStorageFormControllerType from './project-storage-form.controller';

describe('Project storage form controller', () => {
  let ctx:StimulusTestContext;
  let ProjectStorageFormController:typeof ProjectStorageFormControllerType;
  let show:Mock;
  let originalOpenProject:typeof window.OpenProject;

  const pluginContext = () => ({ services: { opModalService: { show } } });

  beforeAll(async () => {
    ({ default: ProjectStorageFormController } = await import('./project-storage-form.controller'));
  });

  beforeEach(async () => {
    show = vi.fn().mockReturnValue(of({
      closingEvent: of({ submitted: true, location: { id: '99', name: 'Shared folder' } }),
    }));
    vi.spyOn(window, 'fetch').mockResolvedValue({
      json: () => Promise.resolve({ _links: { authorizationState: { href: 'connected' } } }),
    } as unknown as Response);

    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve(pluginContext()),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'project-storage-form': ProjectStorageFormController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderForm() {
    await ctx.mount(`
      <div data-controller="project-storage-form"
           data-project-storage-form-folder-mode-value="manual"
           data-project-storage-form-placeholder-folder-name-value="(none)"
           data-project-storage-form-not-logged-in-validation-value="Login required"
           data-project-storage-form-last-project-folders-value='{"manual":"","automatic":""}'>
        <span data-project-storage-form-target="storage"
              data-storage='{"_links":{"self":{"href":"/api/v3/storages/1"}}}'></span>
        <button type="button" data-project-storage-form-target="selectProjectFolderButton"></button>
        <button type="button" data-project-storage-form-target="loginButton"></button>
        <section data-project-storage-form-target="projectFolderSection"></section>
        <input data-project-storage-form-target="projectFolderIdInput" value="">
        <span data-project-storage-form-target="projectFolderIdValidation"></span>
        <span data-project-storage-form-target="selectedFolderText"></span>
      </div>
    `);
    return ctx.getController<ProjectStorageFormControllerType>('project-storage-form');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderForm();

    await expect(controller.services).resolves.toMatchObject({
      opModalService: { show },
    });
  });

  it('opens the location picker and applies the chosen folder', async () => {
    const controller = await renderForm();

    void controller.selectProjectFolder(new CustomEvent('click'));

    await waitFor(() => {
      expect(show).toHaveBeenCalled();
    });
    const folderText = ctx.container.querySelector<HTMLElement>('[data-project-storage-form-target="selectedFolderText"]')!;
    const folderIdInput = ctx.container.querySelector<HTMLInputElement>('[data-project-storage-form-target="projectFolderIdInput"]')!;
    expect(folderText.innerText).toBe('Shared folder');
    expect(folderIdInput.value).toBe('99');
  });

  it('does not open the picker when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderForm();
    const root = ctx.container.querySelector('[data-controller="project-storage-form"]')!;

    void controller.selectProjectFolder(new CustomEvent('click'));
    await ctx.nextFrame();

    root.remove();
    await ctx.nextFrame();

    resolveContext(pluginContext());
    await ctx.nextFrame();

    expect(show).not.toHaveBeenCalled();
  });
});
