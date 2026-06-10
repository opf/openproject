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

import OpShowWhenCheckedController from './show-when-checked.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('OpShowWhenCheckedController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'show-when-checked': OpShowWhenCheckedController },
    });
  });

  afterEach(() => ctx.dispose());

  describe('show-when="checked"', () => {
    beforeEach(async () => {
      await ctx.mount(`
        <div data-controller="show-when-checked">
          <label>
            <input type="checkbox"
                   data-show-when-checked-target="cause"
                   data-target-name="group1">
            Toggle
          </label>
          <div data-show-when-checked-target="effect"
               data-target-name="group1"
               data-show-when="checked"
               hidden
               data-testid="conditional">
            Conditional content
          </div>
        </div>
      `);
    });

    it('shows element when checkbox is checked', async () => {
      const el = ctx.screen.getByTestId('conditional');

      expect(el).not.toBeVisible();

      ctx.screen.getByRole('checkbox', { name: 'Toggle' }).click();
      await ctx.nextFrame();

      expect(el).toBeVisible();
    });

    it('hides element when checkbox is unchecked', async () => {
      const checkbox = ctx.screen.getByRole('checkbox', { name: 'Toggle' });
      const el = ctx.screen.getByTestId('conditional');

      checkbox.click();
      await ctx.nextFrame();

      checkbox.click();
      await ctx.nextFrame();

      expect(el).not.toBeVisible();
    });
  });

  describe('show-when="unchecked"', () => {
    it('hides element when checkbox is checked, shows when unchecked', async () => {
      await ctx.mount(`
        <div data-controller="show-when-checked">
          <label>
            <input type="checkbox"
                   data-show-when-checked-target="cause"
                   data-target-name="group1">
            Toggle
          </label>
          <div data-show-when-checked-target="effect"
               data-target-name="group1"
               data-show-when="unchecked"
               hidden
               data-testid="conditional">
            Shown when unchecked
          </div>
        </div>
      `);

      const checkbox = ctx.screen.getByRole('checkbox', { name: 'Toggle' });
      const el = ctx.screen.getByTestId('conditional');

      expect(el).not.toBeVisible();

      checkbox.click();
      await ctx.nextFrame();

      expect(el.hidden).toBe(true);

      checkbox.click();
      await ctx.nextFrame();

      expect(el).toBeVisible();
    });
  });

  describe('reversed mode', () => {
    it('inverts the checked/unchecked logic', async () => {
      await ctx.mount(`
        <div data-controller="show-when-checked"
             data-show-when-checked-reversed-value="true">
          <label>
            <input type="checkbox"
                   data-show-when-checked-target="cause"
                   data-target-name="group1">
            Toggle
          </label>
          <div data-show-when-checked-target="effect"
               data-target-name="group1"
               data-show-when="checked"
               data-testid="conditional">
            Content
          </div>
        </div>
      `);

      const el = ctx.screen.getByTestId('conditional');

      ctx.screen.getByRole('checkbox', { name: 'Toggle' }).click();
      await ctx.nextFrame();

      expect(el).not.toBeVisible();
    });
  });

  describe('visibility toggle via data-set-visibility', () => {
    it('uses CSS visibility instead of hidden attribute', async () => {
      await ctx.mount(`
        <div data-controller="show-when-checked">
          <label>
            <input type="checkbox"
                   data-show-when-checked-target="cause"
                   data-target-name="group1">
            Toggle
          </label>
          <div data-show-when-checked-target="effect"
               data-target-name="group1"
               data-show-when="checked"
               data-set-visibility="true"
               style="visibility: hidden;"
               data-testid="conditional">
            Content
          </div>
        </div>
      `);

      const el = ctx.screen.getByTestId('conditional');

      expect(el).not.toBeVisible();
      expect(el.hidden).toBe(false);

      ctx.screen.getByRole('checkbox', { name: 'Toggle' }).click();
      await ctx.nextFrame();

      expect(el).toBeVisible();
      expect(el.hidden).toBe(false);
    });
  });
});
