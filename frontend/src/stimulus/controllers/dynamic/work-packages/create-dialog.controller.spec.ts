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
import type CreateDialogControllerType from './create-dialog.controller';

describe('Work package create dialog controller', () => {
  let ctx:StimulusTestContext;
  let CreateDialogController:typeof CreateDialogControllerType;
  let submitForm:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: CreateDialogController } = await import('./create-dialog.controller'));
  });

  beforeEach(async () => {
    submitForm = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({ services: { turboRequests: { submitForm } } }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'work-packages--create-dialog': CreateDialogController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderForm() {
    await ctx.mount(`
      <form data-controller="work-packages--create-dialog"
            data-work-packages--create-dialog-refresh-url-value="/work_packages/dialog/refresh"></form>
    `);
    return ctx.getController<CreateDialogControllerType>('work-packages--create-dialog');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderForm();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { submitForm },
    });
  });

  it('submits the form to the refresh URL', async () => {
    const controller = await renderForm();
    const form = ctx.container.querySelector('form')!;

    void controller.refreshForm();

    await waitFor(() => {
      expect(submitForm).toHaveBeenCalledWith(form, null, '/work_packages/dialog/refresh');
    });
  });

  it('does not submit when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderForm();
    const form = ctx.container.querySelector('form')!;

    void controller.refreshForm();
    await ctx.nextFrame();

    form.remove();
    await ctx.nextFrame();

    resolveContext({ services: { turboRequests: { submitForm } } });
    await ctx.nextFrame();

    expect(submitForm).not.toHaveBeenCalled();
  });
});
