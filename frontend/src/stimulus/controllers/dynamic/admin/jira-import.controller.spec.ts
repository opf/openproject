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

import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext, stubPendingPluginContext, stubPluginContext } from 'core-stimulus/test-helpers';
import type JiraImportControllerType from './jira-import.controller';

describe('Admin JIRA import controller', () => {
  let ctx:StimulusTestContext;
  let JiraImportController:typeof JiraImportControllerType;
  let addError:Mock;

  beforeAll(async () => {
    ({ default: JiraImportController } = await import('./jira-import.controller'));
  });

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] });

    addError = vi.fn();
    stubPluginContext({ services: { notifications: { addError } } });

    ctx = await setupStimulusTest({
      controllers: { 'admin--jira-import': JiraImportController },
    });
  });

  afterEach(() => {
    vi.useRealTimers();
    ctx.dispose();
    vi.restoreAllMocks();
  });

  async function renderPolling() {
    await ctx.mount(`
      <div data-controller="admin--jira-import"
           data-admin--jira-import-url-value="/admin/jira_import/status">
        <div data-admin--jira-import-target="poll"></div>
      </div>
    `);
    return ctx.getController<JiraImportControllerType>('admin--jira-import');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderPolling();

    await expect(controller.services).resolves.toMatchObject({
      notifications: { addError },
    });
  });

  it('reports a failed status poll as an error notification', async () => {
    vi.spyOn(window, 'fetch').mockRejectedValue(new Error('network down'));
    await renderPolling();

    await vi.advanceTimersByTimeAsync(3000);

    expect(addError).toHaveBeenCalledWith(new Error('network down'));
  });

  it('does not notify when disconnected before the plugin context resolves', async () => {
    const resolveContext = stubPendingPluginContext();

    vi.spyOn(window, 'fetch').mockRejectedValue(new Error('network down'));
    await renderPolling();
    const element = ctx.container.querySelector('[data-controller="admin--jira-import"]')!;

    await vi.advanceTimersByTimeAsync(3000);

    element.remove();
    await ctx.nextFrame();

    resolveContext({ services: { notifications: { addError } } });
    await ctx.nextFrame();

    expect(addError).not.toHaveBeenCalled();
  });
});
