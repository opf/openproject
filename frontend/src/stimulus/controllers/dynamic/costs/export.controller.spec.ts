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
import type ExportControllerType from './export.controller';

describe('Costs export controller', () => {
  let ctx:StimulusTestContext;
  let ExportController:typeof ExportControllerType;
  let addError:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: ExportController } = await import('./export.controller'));
  });

  beforeEach(async () => {
    addError = vi.fn();
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({ services: { notifications: { addError } } }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'costs--export': ExportController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderLink() {
    await ctx.mount(`
      <a href="/cost_reports/export.xls"
         data-controller="costs--export"
         data-costs--export-job-status-dialog-url-value="/job_statuses/_job_uuid_/dialog">Export</a>
    `);
    return ctx.getController<ExportControllerType>('costs--export');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderLink();

    await expect(controller.services).resolves.toMatchObject({
      notifications: { addError },
    });
  });

  it('reports a failed export request as an error notification', async () => {
    vi.spyOn(window, 'fetch').mockRejectedValue(new Error('network down'));
    const controller = await renderLink();

    controller.download(new CustomEvent('click'));

    await waitFor(() => {
      expect(addError).toHaveBeenCalledWith(new Error('network down'));
    });
  });

  it('does not notify when disconnected before the plugin context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    vi.spyOn(window, 'fetch').mockRejectedValue(new Error('network down'));
    const controller = await renderLink();
    const link = ctx.container.querySelector('a')!;

    controller.download(new CustomEvent('click'));
    await ctx.nextFrame();

    link.remove();
    await ctx.nextFrame();

    resolveContext({ services: { notifications: { addError } } });
    await ctx.nextFrame();

    expect(addError).not.toHaveBeenCalled();
  });
});
