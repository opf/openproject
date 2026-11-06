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

import MyTimersController from './timers.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('MyTimersController', () => {
  let ctx:StimulusTestContext;

  const elapsed = ():string|null => ctx.container.querySelector('[data-my--timers-target="elapsedTime"]')!.textContent;

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval', 'Date'] });
    vi.setSystemTime(new Date('2026-10-09T11:02:03Z'));

    ctx = await setupStimulusTest({
      controllers: { 'my--timers': MyTimersController },
    });

    await ctx.mount(`
      <div data-controller="my--timers" data-my--timers-start-value="2026-10-09T10:00:00Z">
        <span data-my--timers-target="elapsedTime"></span>
      </div>
    `);
  });

  afterEach(() => {
    ctx.dispose();
    vi.useRealTimers();
  });

  it('renders the elapsed time as soon as it connects', () => {
    expect(elapsed()).toBe('01:02:03');
  });

  it('advances the elapsed time every second', () => {
    vi.advanceTimersByTime(2000);

    expect(elapsed()).toBe('01:02:05');
  });

  it('stops ticking when disconnected', async () => {
    ctx.container.querySelector('[data-controller="my--timers"]')!.remove();
    await ctx.nextFrame();

    expect(vi.getTimerCount()).toBe(0);
  });
});
