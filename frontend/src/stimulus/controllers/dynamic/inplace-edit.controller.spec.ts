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

import { vi, type MockInstance } from 'vitest';
import { userEvent } from 'vitest/browser';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import InplaceEditController from './inplace-edit.controller';

describe('Inplace edit controller', () => {
  let ctx:StimulusTestContext;
  let fetchSpy:MockInstance<typeof window.fetch>;

  beforeEach(async () => {
    fetchSpy = vi.spyOn(window, 'fetch').mockResolvedValue({
      ok: true,
      text: () => Promise.resolve(''),
    } as unknown as Response);

    ctx = await setupStimulusTest({ controllers: { 'inplace-edit': InplaceEditController } });
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
  });

  async function renderDisplayField(action:string) {
    await ctx.mount(`
      <div role="button"
           tabindex="0"
           data-controller="inplace-edit"
           data-inplace-edit-url-value="/inplace_edit"
           data-inplace-edit-dialog-url-value="/inplace_edit_dialog"
           data-action="${action}">Some description text</div>
    `);
    return ctx.screen.getByRole('button');
  }

  function selectTextOf(element:HTMLElement) {
    const range = document.createRange();
    range.selectNodeContents(element);
    window.getSelection()!.removeAllRanges();
    window.getSelection()!.addRange(range);
  }

  describe('request', () => {
    it('does not activate on click while text is selected', async () => {
      const field = await renderDisplayField('click->inplace-edit#request');
      selectTextOf(field);

      field.dispatchEvent(new MouseEvent('click', { bubbles: true }));

      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it('activates on double click although it selects a word', async () => {
      const field = await renderDisplayField('dblclick->inplace-edit#request');

      await userEvent.dblClick(field);

      await vi.waitFor(() => expect(fetchSpy).toHaveBeenCalledWith('/inplace_edit', expect.anything()));
      expect(window.getSelection()!.toString()).toBe('');
    });

    it('does not activate on a single click when bound to double click', async () => {
      const field = await renderDisplayField('dblclick->inplace-edit#request');

      await userEvent.click(field);

      expect(fetchSpy).not.toHaveBeenCalled();
    });
  });

  describe('openDialog', () => {
    it('opens the dialog on double click although it selects a word', async () => {
      const field = await renderDisplayField('dblclick->inplace-edit#openDialog');
      const openDialog = vi.fn();
      field.addEventListener('inplace-edit:open-dialog', openDialog);

      await userEvent.dblClick(field);

      expect(openDialog).toHaveBeenCalled();
    });
  });
});
