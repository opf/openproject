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

import { waitFor } from '@testing-library/dom';
import SelectAutosizeController from './select-autosize.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('SelectAutosizeController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'select-autosize': SelectAutosizeController },
    });
  });

  afterEach(() => ctx.dispose());

  // updateSize is debounced (100ms), so assertions use waitFor
  it('sets size to option count on connect', async () => {
    await ctx.mount(`
      <select data-controller="select-autosize" aria-label="Items">
        <option>A</option>
        <option>B</option>
        <option>C</option>
      </select>
    `);

    const select = ctx.container.querySelector('select')!;

    await waitFor(() => {
      expect(select.size).toBe(3);
    });
  });

  it('respects size limit', async () => {
    const options = Array.from({ length: 15 }, (_, i) => `<option>Item ${i}</option>`).join('');

    await ctx.mount(`
      <select data-controller="select-autosize"
              data-select-autosize-size-limit-value="5"
              aria-label="Items">
        ${options}
      </select>
    `);

    const select = ctx.container.querySelector('select')!;

    await waitFor(() => {
      expect(select.size).toBe(5);
    });
  });

  it('defaults size limit to 10', async () => {
    const options = Array.from({ length: 20 }, (_, i) => `<option>Item ${i}</option>`).join('');

    await ctx.mount(`
      <select data-controller="select-autosize" aria-label="Items">
        ${options}
      </select>
    `);

    const select = ctx.container.querySelector('select')!;

    await waitFor(() => {
      expect(select.size).toBe(10);
    });
  });
});
