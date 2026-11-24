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

import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext, stubPendingPluginContext, stubPluginContext } from 'core-stimulus/test-helpers';
import type ExportControllerType from './export.controller';

describe('Costs export controller', () => {
  let ctx:StimulusTestContext;
  let ExportController:typeof ExportControllerType;
  let addError:Mock;

  beforeAll(async () => {
    ({ default: ExportController } = await import('./export.controller'));
  });

  beforeEach(async () => {
    addError = vi.fn();
    stubPluginContext({ services: { notifications: { addError } } });

    ctx = await setupStimulusTest({
      controllers: { 'costs--export': ExportController },
    });
  });

  afterEach(() => {
    ctx.dispose();
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

  it('reports the server message when the export is refused', async () => {
    vi.spyOn(window, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ message: 'Date (Spent) requires 2 values.' }), { status: 422 }),
    );
    const controller = await renderLink();

    controller.download(new CustomEvent('click'));

    await waitFor(() => {
      expect(addError).toHaveBeenCalledWith(new Error('Date (Spent) requires 2 values.'));
    });
  });

  it('does not notify when disconnected before the plugin context resolves', async () => {
    const resolveContext = stubPendingPluginContext();

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
