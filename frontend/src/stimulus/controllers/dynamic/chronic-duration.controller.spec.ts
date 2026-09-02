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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import ChronicDurationController from './chronic-duration.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('ChronicDurationController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'chronic-duration': ChronicDurationController },
    });
  });

  afterEach(() => ctx.dispose());

  async function mountInput(attributes = ''):Promise<HTMLInputElement> {
    await ctx.mount(`
      <input type="text"
             data-controller="chronic-duration"
             ${attributes}
             aria-label="Duration">
    `);

    return ctx.screen.getByRole('textbox', { name: 'Duration' });
  }

  async function reformat(input:HTMLInputElement, value:string):Promise<string> {
    input.value = value;
    input.dispatchEvent(new Event('blur'));
    await ctx.nextFrame();

    return input.value;
  }

  it('resolves days using the configured hours per day', async () => {
    const input = await mountInput('data-chronic-duration-hours-per-day-value="8"');

    expect(await reformat(input, '1d')).toEqual('8h');
    expect(await reformat(input, '2d 10h')).toEqual('26h');
  });

  it('resolves weeks using the configured days per month', async () => {
    const input = await mountInput(`
      data-chronic-duration-hours-per-day-value="8"
      data-chronic-duration-days-per-month-value="20"
    `);

    expect(await reformat(input, '1w')).toEqual('40h');
  });

  it('honours a non default working day length', async () => {
    const input = await mountInput('data-chronic-duration-hours-per-day-value="6"');

    expect(await reformat(input, '1d')).toEqual('6h');
  });

  it('falls back to a working day when no value is given', async () => {
    const input = await mountInput();

    expect(await reformat(input, '1d')).toEqual('8h');
  });

  it('leaves plain hour values alone', async () => {
    const input = await mountInput('data-chronic-duration-hours-per-day-value="8"');

    expect(await reformat(input, '2.5')).toEqual('2.5h');
  });
});
