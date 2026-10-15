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

import WarningBarController from './warning-bar.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('WarningBarController', () => {
  let ctx:StimulusTestContext;

  const warningBarHeight = () => document.documentElement.style.getPropertyValue('--warning-bar-height');

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'warning-bar': WarningBarController },
    });
  });

  afterEach(() => ctx.dispose());

  it('publishes the height of the bar', async () => {
    await ctx.mount(`
      <div data-controller="warning-bar">
        <div style="height: 42px"></div>
      </div>
    `);

    await waitFor(() => {
      expect(warningBarHeight()).toBe('42px');
    });
  });

  it('publishes the new height when the bar grows', async () => {
    await ctx.mount(`
      <div data-controller="warning-bar">
        <div id="banner" style="height: 42px"></div>
      </div>
    `);
    await waitFor(() => expect(warningBarHeight()).toBe('42px'));

    document.getElementById('banner')!.style.height = '80px';

    await waitFor(() => {
      expect(warningBarHeight()).toBe('80px');
    });
  });

  it('publishes no height for an empty bar', async () => {
    await ctx.mount('<div data-controller="warning-bar"></div>');

    await waitFor(() => {
      expect(warningBarHeight()).toBe('0px');
    });
  });

  it('removes the height when the bar is removed', async () => {
    await ctx.mount(`
      <div data-controller="warning-bar">
        <div style="height: 42px"></div>
      </div>
    `);
    await waitFor(() => expect(warningBarHeight()).toBe('42px'));

    document.querySelector('[data-controller="warning-bar"]')!.remove();

    await waitFor(() => {
      expect(warningBarHeight()).toBe('');
    });
  });
});
