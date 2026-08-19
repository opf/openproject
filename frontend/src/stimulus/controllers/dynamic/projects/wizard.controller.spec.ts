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
import type WizardControllerType from './wizard.controller';

describe('Projects wizard controller', () => {
  let ctx:StimulusTestContext;
  let WizardController:typeof WizardControllerType;
  let requestStream:Mock;
  let projectCreationWizardHelpTextPath:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: WizardController } = await import('./wizard.controller'));
  });

  beforeEach(async () => {
    requestStream = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    projectCreationWizardHelpTextPath = vi.fn().mockReturnValue('/projects/wizard/help_text/42');
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: {
          turboRequests: { requestStream },
          pathHelperService: { projectCreationWizardHelpTextPath },
          currentProject: { identifier: 'my-project' },
        },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'projects--wizard': WizardController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderWizard() {
    await ctx.mount(`
      <div data-controller="projects--wizard">
        <div data-custom-field-id="42">
          <input type="text">
        </div>
      </div>
    `);
    return ctx.getController<WizardControllerType>('projects--wizard');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderWizard();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { requestStream },
      currentProject: { identifier: 'my-project' },
    });
  });

  it('requests the help text for the focused custom field', async () => {
    const controller = await renderWizard();
    const input = ctx.container.querySelector('input')!;

    controller.handleFieldFocus({ target: input } as unknown as FocusEvent);

    await waitFor(() => {
      expect(requestStream).toHaveBeenCalledWith('/projects/wizard/help_text/42');
    });
    expect(projectCreationWizardHelpTextPath).toHaveBeenCalledWith('my-project', '42');
  });

  it('does not request help text when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderWizard();
    const root = ctx.container.querySelector('[data-controller="projects--wizard"]')!;
    const input = ctx.container.querySelector('input')!;

    controller.handleFieldFocus({ target: input } as unknown as FocusEvent);
    await ctx.nextFrame();

    root.remove();
    await ctx.nextFrame();

    resolveContext({
      services: {
        turboRequests: { requestStream },
        pathHelperService: { projectCreationWizardHelpTextPath },
        currentProject: { identifier: 'my-project' },
      },
    });
    await ctx.nextFrame();

    expect(requestStream).not.toHaveBeenCalled();
  });
});
