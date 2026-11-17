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

import { describe, expect, it, vi } from 'vitest';
import { ERROR_TEXT, LIMIT_TEXT, REPEATED_TEXT, SOFT_LIMIT, ToolCalls, ToolLimitExceeded } from '../src/core/toolCalls';
import type { RunEvent } from '../src/shared/types';

function setup() {
  const events:RunEvent[] = [];
  const calls = new ToolCalls((event) => events.push(event));
  return { events, calls };
}

describe('ToolCalls', () => {
  it('returns the earlier result for an identical call, whatever the argument order', async () => {
    const { events, calls } = setup();
    const perform = vi.fn(() => Promise.resolve('result'));

    await calls.run('search', { a: 1, b: 2 }, perform);
    const repeated = await calls.run('search', { b: 2, a: 1 }, perform);

    expect(perform).toHaveBeenCalledTimes(1);
    expect(repeated).toBe(`${REPEATED_TEXT}\nresult`);
    expect(events.map((event) => event.type === 'tool_call' && event.repeated)).toEqual([undefined, true]);
  });

  it('answers "answer now" after a repeat', async () => {
    const { calls } = setup();
    const perform = () => Promise.resolve('x');
    await calls.run('search', {}, perform);
    await calls.run('search', {}, perform);

    expect(await calls.run('other', {}, perform)).toBe(LIMIT_TEXT);
  });

  it('refuses calls after the soft limit and fails after the hard limit', async () => {
    const { calls } = setup();
    for (let index = 0; index < SOFT_LIMIT; index += 1) {
      await calls.run('search', { index }, () => Promise.resolve('x'));
    }

    expect(await calls.run('search', { index: 'late' }, () => Promise.resolve('x'))).toBe(LIMIT_TEXT);
    for (let index = 0; index < 4; index += 1) {
      await calls.run('search', { index: `late${index}` }, () => Promise.resolve('x'));
    }
    await expect(calls.run('search', { index: 'too late' }, () => Promise.resolve('x'))).rejects.toBeInstanceOf(ToolLimitExceeded);
  });

  it('records a failing tool and returns the error text to the model', async () => {
    const { events, calls } = setup();
    expect(await calls.run('search', {}, () => Promise.reject(new Error('boom')))).toBe(ERROR_TEXT);
    expect(events[0]).toMatchObject({ type: 'tool_call', name: 'search', error: 'boom' });
  });
});
