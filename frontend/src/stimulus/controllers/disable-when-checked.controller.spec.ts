/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import OpDisableWhenCheckedController from './disable-when-checked.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('OpDisableWhenCheckedController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'disable-when-checked': OpDisableWhenCheckedController },
    });
  });

  afterEach(() => ctx.dispose());

  describe('basic disable on check', () => {
    beforeEach(async () => {
      await ctx.mount(`
        <div data-controller="disable-when-checked">
          <label>
            <input type="checkbox"
                   data-disable-when-checked-target="cause"
                   data-target-name="group1">
            Toggle
          </label>
          <input type="text"
                 data-disable-when-checked-target="effect"
                 data-target-name="group1"
                 aria-label="Text field">
        </div>
      `);
    });

    it('disables effect targets when cause is checked', async () => {
      const checkbox = ctx.screen.getByRole('checkbox', { name: 'Toggle' });
      const textField = ctx.screen.getByRole('textbox', { name: 'Text field' });

      expect(textField).toBeEnabled();

      checkbox.click();
      await ctx.nextFrame();

      expect(textField).toBeDisabled();
    });

    it('re-enables effect targets when cause is unchecked', async () => {
      const checkbox = ctx.screen.getByRole('checkbox', { name: 'Toggle' });
      const textField = ctx.screen.getByRole('textbox', { name: 'Text field' });

      checkbox.click();
      await ctx.nextFrame();

      expect(textField).toBeDisabled();

      checkbox.click();
      await ctx.nextFrame();

      expect(textField).toBeEnabled();
    });
  });

  describe('reversed mode', () => {
    beforeEach(async () => {
      await ctx.mount(`
        <div data-controller="disable-when-checked"
             data-disable-when-checked-reversed-value="true">
          <label>
            <input type="checkbox"
                   data-disable-when-checked-target="cause"
                   data-target-name="group1">
            Toggle
          </label>
          <input type="text"
                 data-disable-when-checked-target="effect"
                 data-target-name="group1"
                 aria-label="Text field">
        </div>
      `);
    });

    it('enables effect targets when cause is checked', async () => {
      const checkbox = ctx.screen.getByRole('checkbox', { name: 'Toggle' });
      const textField = ctx.screen.getByRole('textbox', { name: 'Text field' });

      checkbox.click();
      await ctx.nextFrame();

      expect(textField).toBeEnabled();
    });
  });

  describe('select option handling', () => {
    it('resets select value when selected option becomes disabled', async () => {
      await ctx.mount(`
        <div data-controller="disable-when-checked">
          <label>
            <input type="checkbox"
                   data-disable-when-checked-target="cause"
                   data-target-name="opts">
            Toggle
          </label>
          <select aria-label="Options">
            <option value="">-- Select --</option>
            <option value="a"
                    data-disable-when-checked-target="effect"
                    data-target-name="opts"
                    selected>Option A</option>
            <option value="b">Option B</option>
          </select>
        </div>
      `);

      const select = ctx.container.querySelector<HTMLSelectElement>('select[aria-label="Options"]')!;

      expect(select.value).toBe('a');

      ctx.screen.getByRole('checkbox', { name: 'Toggle' }).click();
      await ctx.nextFrame();

      expect(select.value).toBe('');
    });
  });
});
