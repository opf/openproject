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
import { vi } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type CustomFieldsControllerType from './custom-fields.controller';

class FakeAutoscroll {
  static constructedWith:unknown[][] = [];

  constructor(...args:unknown[]) {
    FakeAutoscroll.constructedWith.push(args);
  }
}

describe('Admin custom fields controller', () => {
  let ctx:StimulusTestContext;
  let CustomFieldsController:typeof CustomFieldsControllerType;
  let originalOpenProject:typeof window.OpenProject;

  const pluginContext = () => ({ classes: { DomAutoscrollService: FakeAutoscroll } });

  beforeAll(async () => {
    ({ default: CustomFieldsController } = await import('./custom-fields.controller'));
  });

  beforeEach(async () => {
    FakeAutoscroll.constructedWith = [];
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve(pluginContext()),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'admin--custom-fields': CustomFieldsController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderOptions() {
    await ctx.mount(`
      <div data-controller="admin--custom-fields">
        <table>
          <tbody data-admin--custom-fields-target="dragContainer">
            <tr data-admin--custom-fields-target="customOptionRow"><td>one</td></tr>
            <tr data-admin--custom-fields-target="customOptionRow"><td>two</td></tr>
          </tbody>
        </table>
      </div>
    `);
    return ctx.getController<CustomFieldsControllerType>('admin--custom-fields');
  }

  it('sets up autoscroll once connected', async () => {
    await renderOptions();

    await waitFor(() => {
      expect(FakeAutoscroll.constructedWith).toHaveLength(1);
    });
  });

  it('moves a custom option row up', async () => {
    const controller = await renderOptions();
    const rows = ctx.container.querySelectorAll('tr');

    controller.moveRowUp({ target: rows[1].querySelector('td')! });

    const cells = Array.from(ctx.container.querySelectorAll('td')).map((cell) => cell.textContent);
    expect(cells).toEqual(['two', 'one']);
  });

  it('does not set up autoscroll when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    await renderOptions();
    const root = ctx.container.querySelector('[data-controller="admin--custom-fields"]')!;

    root.remove();
    await ctx.nextFrame();

    resolveContext(pluginContext());
    await ctx.nextFrame();

    expect(FakeAutoscroll.constructedWith).toHaveLength(0);
  });
});
