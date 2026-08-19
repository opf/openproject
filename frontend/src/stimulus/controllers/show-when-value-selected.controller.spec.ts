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

import OpShowWhenValueSelectedController from './show-when-value-selected.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('OpShowWhenValueSelectedController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'show-when-value-selected': OpShowWhenValueSelectedController },
    });
  });

  afterEach(() => ctx.dispose());

  describe('data-value matching', () => {
    beforeEach(async () => {
      await ctx.mount(`
        <div data-controller="show-when-value-selected">
          <select data-show-when-value-selected-target="cause"
                  data-target-name="type"
                  aria-label="Type">
            <option value="">-- Select --</option>
            <option value="a">Type A</option>
            <option value="b">Type B</option>
          </select>
          <input type="text"
                 data-show-when-value-selected-target="effect"
                 data-target-name="type"
                 data-value="a"
                 hidden
                 disabled
                 aria-label="Effect A">
          <input type="text"
                 data-show-when-value-selected-target="effect"
                 data-target-name="type"
                 data-value="b"
                 hidden
                 disabled
                 aria-label="Effect B">
        </div>
      `);
    });

    it('shows matching effect and hides non-matching', async () => {
      const select = ctx.container.querySelector<HTMLSelectElement>('select[aria-label="Type"]')!;
      const effectA = ctx.container.querySelector<HTMLInputElement>('input[aria-label="Effect A"]')!;
      const effectB = ctx.container.querySelector<HTMLInputElement>('input[aria-label="Effect B"]')!;

      expect(effectA.hidden).toBe(true);
      expect(effectA).toBeDisabled();
      expect(effectB.hidden).toBe(true);
      expect(effectB).toBeDisabled();

      select.value = 'a';
      select.dispatchEvent(new Event('change', { bubbles: true }));
      await ctx.nextFrame();

      expect(effectA.hidden).toBe(false);
      expect(effectA).toBeEnabled();
      expect(effectB.hidden).toBe(true);
      expect(effectB).toBeDisabled();
    });

    it('swaps visibility when selection changes', async () => {
      const select = ctx.container.querySelector<HTMLSelectElement>('select[aria-label="Type"]')!;
      const effectA = ctx.container.querySelector<HTMLInputElement>('input[aria-label="Effect A"]')!;
      const effectB = ctx.container.querySelector<HTMLInputElement>('input[aria-label="Effect B"]')!;

      expect(effectA.hidden).toBe(true);
      expect(effectA).toBeDisabled();
      expect(effectB.hidden).toBe(true);
      expect(effectB).toBeDisabled();

      select.value = 'a';
      select.dispatchEvent(new Event('change', { bubbles: true }));
      await ctx.nextFrame();

      select.value = 'b';
      select.dispatchEvent(new Event('change', { bubbles: true }));
      await ctx.nextFrame();

      expect(effectA.hidden).toBe(true);
      expect(effectA).toBeDisabled();
      expect(effectB.hidden).toBe(false);
      expect(effectB).toBeEnabled();
    });
  });

  describe('data-not-value matching', () => {
    it('hides effect when select matches not-value', async () => {
      await ctx.mount(`
        <div data-controller="show-when-value-selected">
          <select data-show-when-value-selected-target="cause"
                  data-target-name="mode"
                  aria-label="Mode">
            <option value="simple">Simple</option>
            <option value="advanced">Advanced</option>
          </select>
          <input type="text"
                 data-show-when-value-selected-target="effect"
                 data-target-name="mode"
                 data-not-value="simple"
                 hidden
                 disabled
                 aria-label="Advanced options">
        </div>
      `);

      const select = ctx.container.querySelector<HTMLSelectElement>('select[aria-label="Mode"]')!;
      const effect = ctx.container.querySelector<HTMLInputElement>('input[aria-label="Advanced options"]')!;

      expect(effect.hidden).toBe(true);
      expect(effect).toBeDisabled();

      select.value = 'simple';
      select.dispatchEvent(new Event('change', { bubbles: true }));
      await ctx.nextFrame();

      expect(effect.hidden).toBe(true);
      expect(effect).toBeDisabled();

      select.value = 'advanced';
      select.dispatchEvent(new Event('change', { bubbles: true }));
      await ctx.nextFrame();

      expect(effect.hidden).toBe(false);
      expect(effect).toBeEnabled();
    });
  });
});
