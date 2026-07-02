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
import { Subject } from 'rxjs';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type BacklogsControllerType from './backlogs.controller';

interface HalEvent {
  eventType:string;
}

describe('Backlogs controller', () => {
  let ctx:StimulusTestContext;
  let BacklogsController:typeof BacklogsControllerType;
  let events$:Subject<HalEvent[]>;
  let aggregated$:Mock;
  let reload:Mock;
  let originalOpenProject:typeof window.OpenProject;

  const pluginContext = () => ({
    services: { halEvents: { aggregated$ } },
  });

  beforeAll(async () => {
    ({ default: BacklogsController } = await import('./backlogs.controller'));
  });

  beforeEach(async () => {
    events$ = new Subject<HalEvent[]>();
    aggregated$ = vi.fn(() => events$);
    reload = vi.fn(() => Promise.resolve());
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve(pluginContext()),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { backlogs: BacklogsController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderBacklogs() {
    await ctx.mount(`
      <div data-controller="backlogs">
        <turbo-frame id="backlogs_container"></turbo-frame>
      </div>
    `);
    const frame = ctx.container.querySelector('#backlogs_container')!;
    (frame as unknown as { reload:Mock }).reload = reload;
    return ctx.getController<BacklogsControllerType>('backlogs');
  }

  it('subscribes to aggregated work package events once connected', async () => {
    await renderBacklogs();

    await waitFor(() => {
      expect(aggregated$).toHaveBeenCalledWith('WorkPackage');
    });
  });

  it('reloads the list frame on an updated event', async () => {
    await renderBacklogs();
    await waitFor(() => { expect(aggregated$).toHaveBeenCalled(); });

    events$.next([{ eventType: 'updated' }]);

    await waitFor(() => {
      expect(reload).toHaveBeenCalled();
    });
  });

  it('ignores event batches without an update', async () => {
    await renderBacklogs();
    await waitFor(() => { expect(aggregated$).toHaveBeenCalled(); });

    events$.next([{ eventType: 'created' }]);
    await ctx.nextFrame();

    expect(reload).not.toHaveBeenCalled();
  });

  it('stops reloading once disconnected', async () => {
    await renderBacklogs();
    await waitFor(() => { expect(aggregated$).toHaveBeenCalled(); });

    const root = ctx.container.querySelector('[data-controller="backlogs"]')!;
    root.remove();
    await ctx.nextFrame();

    events$.next([{ eventType: 'updated' }]);
    await ctx.nextFrame();

    expect(reload).not.toHaveBeenCalled();
  });

  it('does not subscribe when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    await renderBacklogs();
    const root = ctx.container.querySelector('[data-controller="backlogs"]')!;

    root.remove();
    await ctx.nextFrame();

    resolveContext(pluginContext());
    await ctx.nextFrame();

    expect(aggregated$).not.toHaveBeenCalled();
  });
});
