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

import { type MutationExit, RowMutations } from './row-mutations';

describe('RowMutations', () => {
  let calls:string[];
  let exits:MutationExit[];
  let pending:boolean;
  let mutations:RowMutations;

  beforeEach(() => {
    calls = [];
    exits = [];
    pending = false;
    mutations = new RowMutations({
      enter: (accumulate) => calls.push(`enter:${accumulate}`),
      exit: (exit) => { calls.push('exit'); exits.push(exit); },
    }, () => pending);
  });

  it('runs enter, change, exit in order for one mutation', () => {
    mutations.run(new Set(['a']), () => calls.push('change'));

    expect(calls).toEqual(['enter:false', 'change', 'exit']);
    expect(exits).toEqual([{ scope: new Set(['a']), rendered: false }]);
  });

  it('widens nested scopes and exits once', () => {
    mutations.run(new Set(['a']), () => {
      mutations.run(new Set(['b']), () => calls.push('inner'));
      expect(mutations.depth).toBe(1);
    });

    expect(calls).toEqual(['enter:false', 'enter:true', 'inner', 'exit']);
    expect(exits).toEqual([{ scope: new Set(['a', 'b']), rendered: false }]);
    expect(mutations.depth).toBe(0);
  });

  it('lets a nested all scope absorb keyed scopes', () => {
    mutations.run(new Set(['a']), () => {
      mutations.run('all', () => undefined);
      mutations.run(new Set(['c']), () => undefined);
    });

    expect(exits).toEqual([{ scope: 'all', rendered: false }]);
  });

  it('widens a positions-only scope joined with keyed rows to all', () => {
    mutations.run('positions', () => {
      mutations.run(new Set(['a']), () => undefined);
    });
    mutations.run(new Set(['b']), () => {
      mutations.run('positions', () => undefined);
    });

    expect(exits).toEqual([{ scope: 'all', rendered: false }, { scope: 'all', rendered: false }]);
  });

  it('keeps positions-only scopes positions-only when joined with no rows', () => {
    mutations.run('positions', () => {
      mutations.run('positions', () => undefined);
      mutations.run(new Set(), () => undefined);
    });

    expect(exits).toEqual([{ scope: 'positions', rendered: false }]);
  });

  it('treats an empty scope as naming no rows', () => {
    mutations.run(new Set(), () => {
      mutations.run(new Set(['a']), () => undefined);
    });

    expect(exits).toEqual([{ scope: new Set(['a']), rendered: false }]);
  });

  it('paints and releases after a throwing nested change', () => {
    const run = () => mutations.run(new Set(['a']), () => {
      mutations.run(new Set(['b']), () => { throw new Error('boom'); });
    });

    expect(run).toThrow('boom');
    expect(exits).toEqual([{ scope: new Set(['a', 'b']), rendered: false }]);
    expect(mutations.depth).toBe(0);

    mutations.run(new Set(['c']), () => undefined);
    expect(exits).toHaveLength(2);
    expect(calls.filter((call) => call === 'enter:false')).toHaveLength(2);
  });

  it('marks the exit rendered when any nested run rendered', () => {
    mutations.run(new Set(['a']), () => {
      mutations.run('all', () => undefined, { rendered: true });
    });

    expect(exits).toEqual([{ scope: 'all', rendered: true }]);
  });

  it('accumulates ownership on entry while a render is pending', () => {
    pending = true;

    mutations.run(new Set(['a']), () => undefined);

    expect(calls[0]).toBe('enter:true');
  });
});
