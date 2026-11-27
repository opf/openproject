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
import type SubmitControllerType from './submit.controller';

describe('Meetings submit controller', () => {
  let ctx:StimulusTestContext;
  let SubmitController:typeof SubmitControllerType;
  let request:Mock;

  beforeAll(async () => {
    ({ default: SubmitController } = await import('./submit.controller'));
  });

  beforeEach(async () => {
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    stubPluginContext({ services: { turboRequests: { request } } });

    ctx = await setupStimulusTest({
      controllers: { 'meetings--submit': SubmitController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
  });

  async function renderActions() {
    await ctx.mount(`
      <div data-controller="meetings--submit">
        <a data-href="/meetings/1/change_state" data-method="PUT">Close meeting</a>
      </div>
    `);
    return ctx.getController<SubmitControllerType>('meetings--submit');
  }

  function fakeClick(target:Element):Event {
    return { preventDefault: vi.fn(), currentTarget: target } as unknown as Event;
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderActions();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
    });
  });

  it('sends the intercepted action as a turbo stream request', async () => {
    const controller = await renderActions();
    const link = ctx.container.querySelector('a')!;

    controller.intercept(fakeClick(link));

    await waitFor(() => {
      expect(request).toHaveBeenCalled();
    });
    const [url, options] = request.mock.calls[0] as [string, { method:string }];
    expect(url).toContain('/meetings/1/change_state');
    expect(options.method).toBe('PUT');
  });

  it('does not send when disconnected before the context resolves', async () => {
    const resolveContext = stubPendingPluginContext();

    const controller = await renderActions();
    const root = ctx.container.querySelector('[data-controller="meetings--submit"]')!;
    const link = ctx.container.querySelector('a')!;

    controller.intercept(fakeClick(link));
    await ctx.nextFrame();

    root.remove();
    await ctx.nextFrame();

    resolveContext({ services: { turboRequests: { request } } });
    await ctx.nextFrame();

    expect(request).not.toHaveBeenCalled();
  });

  describe('turbo:before-visit', () => {
    let pageHasUnsavedChanges:boolean;
    let confirm:Mock<typeof window.confirm>;

    beforeEach(() => {
      pageHasUnsavedChanges = false;
      Object.defineProperties(window.OpenProject, {
        pageHasUnsavedChanges: { get: () => pageHasUnsavedChanges, configurable: true },
        pageWasEdited: { get: () => false, configurable: true },
      });
      confirm = vi.spyOn(window, 'confirm').mockReturnValue(false);
    });

    async function renderForm() {
      await ctx.mount(`
        <div data-controller="meetings--submit">
          <input type="text" name="title" data-initial-value="Title" value="Title">
        </div>
      `);
      return ctx.container.querySelector<HTMLInputElement>('input[name="title"]')!;
    }

    function visit():CustomEvent {
      const event = new CustomEvent('turbo:before-visit', { cancelable: true });
      document.dispatchEvent(event);
      return event;
    }

    it('confirms when an agenda input changed and prevents the visit on dismiss', async () => {
      const input = await renderForm();
      input.value = 'Changed';

      const event = visit();

      expect(confirm).toHaveBeenCalledTimes(1);
      expect(event.defaultPrevented).toBe(true);
    });

    it('lets the visit proceed when the user accepts', async () => {
      const input = await renderForm();
      input.value = 'Changed';
      confirm.mockReturnValue(true);

      const event = visit();

      expect(confirm).toHaveBeenCalledTimes(1);
      expect(event.defaultPrevented).toBe(false);
    });

    it('does not confirm for an unchanged edit form', async () => {
      await renderForm();

      const event = visit();

      expect(confirm).not.toHaveBeenCalled();
      expect(event.defaultPrevented).toBe(false);
    });

    it('does not confirm when the global guard will ask', async () => {
      const input = await renderForm();
      input.value = 'Changed';
      pageHasUnsavedChanges = true;

      const event = visit();

      expect(confirm).not.toHaveBeenCalled();
      expect(event.defaultPrevented).toBe(false);
    });

    it('ignores dirty inputs outside the controller element', async () => {
      await renderForm();
      const outside = document.createElement('input');
      outside.type = 'text';
      outside.value = 'typed';
      ctx.container.append(outside);

      visit();

      expect(confirm).not.toHaveBeenCalled();
    });

    it('stops listening after disconnect', async () => {
      const input = await renderForm();
      input.value = 'Changed';
      ctx.container.querySelector('[data-controller="meetings--submit"]')!.remove();
      await ctx.nextFrame();

      visit();

      expect(confirm).not.toHaveBeenCalled();
    });
  });
});
