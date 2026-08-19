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

import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type MatchPreviewDialogControllerType from './match-preview-dialog.controller';

describe('Match preview dialog controller', () => {
  let ctx:StimulusTestContext;
  let MatchPreviewDialogController:typeof MatchPreviewDialogControllerType;
  let request:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: MatchPreviewDialogController } = await import('./match-preview-dialog.controller'));
  });

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });

    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({ services: { turboRequests: { request } } }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'openid-connect--match-preview-dialog': MatchPreviewDialogController },
    });
  });

  afterEach(() => {
    vi.useRealTimers();
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderDialog() {
    await ctx.mount(`
      <dialog data-controller="openid-connect--match-preview-dialog"
              data-openid-connect--match-preview-dialog-update-url-value="/oidc/match_preview">
        <input data-openid-connect--match-preview-dialog-target="regexpInput" value="^op-.*$">
        <input data-openid-connect--match-preview-dialog-target="groupNamesInput" value="op-admins">
      </dialog>
    `);
    return ctx.getController<MatchPreviewDialogControllerType>('openid-connect--match-preview-dialog');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderDialog();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
    });
  });

  it('posts the match preview after the input debounce', async () => {
    await renderDialog();
    const regexpInput = ctx.container.querySelector<HTMLInputElement>('input')!;

    regexpInput.dispatchEvent(new Event('input'));
    await vi.advanceTimersByTimeAsync(500);

    expect(request).toHaveBeenCalledTimes(1);
    const [url, options] = request.mock.calls[0] as [string, { method:string, body:string }];
    expect(url).toBe('/oidc/match_preview');
    expect(options.method).toBe('POST');
    expect(JSON.parse(options.body)).toEqual({
      preview_group_names: 'op-admins',
      preview_regular_expressions: '^op-.*$',
    });
  });

  it('does not post when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    await renderDialog();
    const dialog = ctx.container.querySelector('dialog')!;
    const regexpInput = ctx.container.querySelector<HTMLInputElement>('input')!;

    regexpInput.dispatchEvent(new Event('input'));
    await vi.advanceTimersByTimeAsync(500);

    dialog.remove();
    await ctx.nextFrame();

    resolveContext({ services: { turboRequests: { request } } });
    await ctx.nextFrame();

    expect(request).not.toHaveBeenCalled();
  });
});
