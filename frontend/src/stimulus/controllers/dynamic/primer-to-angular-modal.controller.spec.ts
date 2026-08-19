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
import type PrimerToAngularModalControllerType from './primer-to-angular-modal.controller';

describe('Primer to Angular modal controller', () => {
  let ctx:StimulusTestContext;
  let PrimerToAngularModalController:typeof PrimerToAngularModalControllerType;
  let closeMe:Mock;
  let originalOpenProject:typeof window.OpenProject;

  const pluginContext = () => ({
    services: { opModalService: { activeModalInstance$: { value: { closeMe } } } },
  });

  beforeAll(async () => {
    ({ default: PrimerToAngularModalController } = await import('./primer-to-angular-modal.controller'));
  });

  beforeEach(async () => {
    closeMe = vi.fn();
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve(pluginContext()),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'primer-to-angular-modal': PrimerToAngularModalController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderModal() {
    await ctx.mount('<div data-controller="primer-to-angular-modal"></div>');
    return ctx.getController<PrimerToAngularModalControllerType>('primer-to-angular-modal');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderModal();

    await expect(controller.services).resolves.toMatchObject({
      opModalService: { activeModalInstance$: { value: { closeMe } } },
    });
  });

  it('closes the active Angular modal', async () => {
    const controller = await renderModal();
    const event = new CustomEvent('click');

    void controller.close(event);

    await waitFor(() => {
      expect(closeMe).toHaveBeenCalledWith(event);
    });
  });

  it('does not close when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderModal();
    const root = ctx.container.querySelector('[data-controller="primer-to-angular-modal"]')!;

    void controller.close(new CustomEvent('click'));
    await ctx.nextFrame();

    root.remove();
    await ctx.nextFrame();

    resolveContext(pluginContext());
    await ctx.nextFrame();

    expect(closeMe).not.toHaveBeenCalled();
  });
});
