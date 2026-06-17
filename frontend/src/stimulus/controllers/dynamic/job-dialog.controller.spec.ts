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
import { TurboHelpers } from 'core-turbo/helpers';
import type AsyncJobDialogControllerType from './job-dialog.controller';

describe('Job dialog controller', () => {
  let ctx:StimulusTestContext;
  let AsyncJobDialogController:typeof AsyncJobDialogControllerType;
  let addError:Mock;
  let jobStatusModalPath:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: AsyncJobDialogController } = await import('./job-dialog.controller'));
  });

  beforeEach(async () => {
    addError = vi.fn();
    jobStatusModalPath = vi.fn().mockReturnValue('/job_statuses/abc/dialog');
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: {
          notifications: { addError },
          pathHelperService: { jobStatusModalPath },
        },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'job-dialog': AsyncJobDialogController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderLink() {
    await ctx.mount('<a href="/exports/run" data-controller="job-dialog">Run export</a>');
    return ctx.container.querySelector('a')!;
  }

  it('binds the declared services after connect', async () => {
    await renderLink();
    const controller = ctx.getController<AsyncJobDialogControllerType>('job-dialog');

    await expect(controller.services).resolves.toMatchObject({
      notifications: { addError },
      pathHelperService: { jobStatusModalPath },
    });
  });

  it('requests the job and consults the job status modal path on click', async () => {
    vi.spyOn(window, 'fetch')
      .mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ job_id: 'abc' }),
      } as unknown as Response)
      .mockResolvedValueOnce({
        ok: false,
        statusText: 'nope',
      } as unknown as Response);
    const link = await renderLink();

    link.click();

    await waitFor(() => {
      expect(addError).toHaveBeenCalledWith(new Error('nope'));
    });
    expect(jobStatusModalPath).toHaveBeenCalledWith('abc');
  });

  it('runs a click arriving before the plugin context resolves once it does', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const fetchSpy = vi.spyOn(window, 'fetch')
      .mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ job_id: 'abc' }),
      } as unknown as Response)
      .mockResolvedValueOnce({
        ok: true,
        text: () => Promise.resolve(''),
      } as unknown as Response);
    const link = await renderLink();

    const notPrevented = link.dispatchEvent(new MouseEvent('click', { cancelable: true }));

    expect(notPrevented).toBe(false);
    expect(fetchSpy).not.toHaveBeenCalled();

    resolveContext({
      services: {
        notifications: { addError },
        pathHelperService: { jobStatusModalPath },
      },
    });

    await waitFor(() => {
      expect(jobStatusModalPath).toHaveBeenCalledWith('abc');
    });
  });

  it('leaves the progress bar alone when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const showProgressBar = vi.spyOn(TurboHelpers, 'showProgressBar');
    const fetchSpy = vi.spyOn(window, 'fetch').mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ job_id: 'abc' }),
    } as unknown as Response);
    const link = await renderLink();

    link.click();

    link.remove();
    await ctx.nextFrame();

    resolveContext({
      services: {
        notifications: { addError },
        pathHelperService: { jobStatusModalPath },
      },
    });
    await ctx.nextFrame();

    expect(showProgressBar).not.toHaveBeenCalled();
    expect(fetchSpy).not.toHaveBeenCalled();
    expect(jobStatusModalPath).not.toHaveBeenCalled();
    expect(addError).not.toHaveBeenCalled();
  });
});
