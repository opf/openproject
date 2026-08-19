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
import type FormControllerType from './form.controller';

describe('Meetings form controller', () => {
  let ctx:StimulusTestContext;
  let FormController:typeof FormControllerType;
  let request:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: FormController } = await import('./form.controller'));
  });

  beforeEach(async () => {
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: {
          turboRequests: { request },
          pathHelperService: { staticBase: '/op' },
        },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'meetings--form': FormController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderForm() {
    await ctx.mount(`
      <form data-controller="meetings--form">
        <input name="meeting[start_date]" value="2026-06-11">
        <input name="meeting[start_time_hour]" value="10:00">
      </form>
    `);
    return ctx.getController<FormControllerType>('meetings--form');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderForm();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
    });
  });

  it('requests the timezone turbo stream with the form values', async () => {
    const controller = await renderForm();

    void controller.updateTimezoneText();

    await waitFor(() => {
      expect(request).toHaveBeenCalled();
    });
    const url = request.mock.calls[0][0] as string;
    expect(url).toContain('/op/meetings/fetch_timezone?');
    expect(url).toContain(encodeURIComponent('meeting[start_date]'));
    expect(url).toContain('2026-06-11');
  });

  it('does not request when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderForm();
    const form = ctx.container.querySelector('form')!;

    void controller.updateTimezoneText();
    await ctx.nextFrame();

    form.remove();
    await ctx.nextFrame();

    resolveContext({
      services: {
        turboRequests: { request },
        pathHelperService: { staticBase: '/op' },
      },
    });
    await ctx.nextFrame();

    expect(request).not.toHaveBeenCalled();
  });
});
