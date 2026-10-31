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

import { expectTypeOf } from 'vitest';
import { Decoder, SelectionAdapter, SelectionIssue, decodeAll } from './selection-adapter';

const decodeNumber:Decoder<number> = (raw) => (
  typeof raw === 'number'
    ? { ok: true, value: raw }
    : { ok: false, issue: { code: 'invalid-shape' } }
);

const captureMessage = vi.fn();

beforeEach(() => {
  captureMessage.mockReset();
  vi.stubGlobal('ErrorReporter', { captureMessage });
});

afterEach(() => {
  vi.unstubAllGlobals();
});

expectTypeOf<SelectionAdapter<number>['setValue']>().parameter(0).toEqualTypeOf<number>();
expectTypeOf<SelectionAdapter<number>['setValue']>().parameter(0).not.toEqualTypeOf<unknown>();
expectTypeOf<SelectionAdapter<number>['bridge']['accept']>().parameter(0).toEqualTypeOf<unknown>();
expectTypeOf<SelectionAdapter<number>['bridge']['load']>().parameter(0).toEqualTypeOf<unknown>();

const createAdapter = () => new SelectionAdapter<number>(
  decodeNumber,
  null,
  (value) => value,
  (a, b) => a === b,
  (value) => (typeof value === 'number' ? value : undefined),
);

describe('SelectionAdapter', () => {
  it('load sets a ready state and the raw model without emitting', () => {
    const adapter = createAdapter();
    const emitted:number[] = [];
    adapter.changes$.subscribe((value) => emitted.push(value));

    adapter.bridge.load(1);

    expect(adapter.state).toEqual({ kind: 'ready', value: 1 });
    expect(adapter.bridge.model).toBe(1);
    expect(emitted).toEqual([]);
  });

  it('accept of a valid value emits once and updates the state', () => {
    const adapter = createAdapter();
    const emitted:number[] = [];
    adapter.changes$.subscribe((value) => emitted.push(value));

    adapter.bridge.accept(2);

    expect(emitted).toEqual([2]);
    expect(adapter.state).toEqual({ kind: 'ready', value: 2 });
    expect(adapter.bridge.model).toBe(2);
  });

  it('accept of an invalid value displays the last accepted value and keeps the payload as rejected', () => {
    const adapter = createAdapter();
    const emitted:number[] = [];
    adapter.changes$.subscribe((value) => emitted.push(value));
    adapter.bridge.load(1);

    adapter.bridge.accept('x');

    expect(adapter.state).toEqual({ kind: 'invalid', issue: { code: 'invalid-shape' }, lastAccepted: 1 });
    expect(adapter.bridge.model).toBe(1);
    expect(adapter.bridge.rejected).toBe('x');
    expect(emitted).toEqual([]);
  });

  it('accept of an invalid value without a last accepted value displays the empty model', () => {
    const adapter = new SelectionAdapter<number>(decodeNumber, 'empty', (value) => value, () => true, () => undefined);

    adapter.bridge.accept('x');

    expect(adapter.bridge.model).toBe('empty');
    expect(adapter.bridge.rejected).toBe('x');
  });

  it('resets the control to the restored model only on an invalid accept', () => {
    const adapter = createAdapter();
    const control = { writeValue: vi.fn() };
    adapter.bridge.load(1);

    adapter.bridge.accept(2, control);
    expect(control.writeValue).not.toHaveBeenCalled();

    adapter.bridge.accept('x', control);
    expect(control.writeValue).toHaveBeenCalledExactlyOnceWith(2);
  });

  it.each([
    ['a valid accept', (adapter:SelectionAdapter<number>) => adapter.bridge.accept(2)],
    ['a valid load', (adapter:SelectionAdapter<number>) => adapter.bridge.load(2)],
    ['setValue', (adapter:SelectionAdapter<number>) => adapter.setValue(2)],
  ])('clears the rejected payload on %s', (_name, recover) => {
    const adapter = createAdapter();
    adapter.bridge.accept('x');

    recover(adapter);

    expect(adapter.bridge.rejected).toBeUndefined();
    expect(adapter.bridge.model).toBe(2);
  });

  it('keeps the last accepted value across consecutive invalid input', () => {
    const adapter = createAdapter();
    adapter.bridge.load(1);
    adapter.bridge.accept('x');
    adapter.bridge.accept('y');

    expect(adapter.state).toEqual({ kind: 'invalid', issue: { code: 'invalid-shape' }, lastAccepted: 1 });
  });

  it('load of invalid initial data is invalid without lastAccepted and uses the empty model', () => {
    const adapter = createAdapter();

    adapter.bridge.load('x');

    expect(adapter.state).toEqual({ kind: 'invalid', issue: { code: 'invalid-shape' } });
    expect(adapter.bridge.model).toBeNull();
  });

  it('setValue updates state and derives the model via toModel, without emitting', () => {
    const adapter = new SelectionAdapter<number>(decodeNumber, null, (value) => ({ id: value }), () => true, () => undefined);
    const emitted:number[] = [];
    adapter.changes$.subscribe((value) => emitted.push(value));

    adapter.setValue(5);

    expect(adapter.state).toEqual({ kind: 'ready', value: 5 });
    expect(adapter.bridge.model).toEqual({ id: 5 });
    expect(emitted).toEqual([]);
  });

  it('emits state changes on stateChanges$', () => {
    const adapter = createAdapter();
    const states:string[] = [];
    adapter.stateChanges$.subscribe((state) => states.push(state.kind));

    adapter.bridge.accept(1);
    adapter.bridge.accept('x');

    expect(states).toEqual(['invalid', 'ready', 'invalid']);
  });

  it('keeps bridge callbacks stable and detached from the bridge receiver', () => {
    const adapter = createAdapter();
    const { compareWith, trackBy } = adapter.bridge;

    expect(adapter.bridge.compareWith).toBe(compareWith);
    expect(adapter.bridge.trackBy).toBe(trackBy);
    expect(compareWith(1, 1)).toBe(true);
    expect(trackBy(3)).toBe(3);
  });
});

describe('SelectionAdapter error reporting', () => {
  it('reports only the issue code of an invalid accept', () => {
    const adapter = createAdapter();
    adapter.bridge.load(1);

    adapter.bridge.accept({ secret: 'payload' });

    expect(captureMessage).toHaveBeenCalledExactlyOnceWith('selection:invalid-shape');
  });

  it('reports only the issue code of an invalid load', () => {
    const adapter = createAdapter();

    adapter.bridge.load({ secret: 'payload' });

    expect(captureMessage).toHaveBeenCalledExactlyOnceWith('selection:invalid-shape');
  });

  it('does not report valid loads and accepts', () => {
    const adapter = createAdapter();

    adapter.bridge.load(1);
    adapter.bridge.accept(2);

    expect(captureMessage).not.toHaveBeenCalled();
  });
});

describe('decodeAll', () => {
  const decodeOne = (value:unknown, index:number):{ ok:true; value:number }|{ ok:false; issue:SelectionIssue } => (
    typeof value === 'number'
      ? { ok: true, value }
      : { ok: false, issue: { code: 'invalid-shape', index } }
  );

  it('fails atomically with the index of the first failure', () => {
    expect(decodeAll([1, 'x', 3], decodeOne)).toEqual({ ok: false, issue: { code: 'invalid-shape', index: 1 } });
  });

  it('preserves order and duplicates', () => {
    expect(decodeAll([3, 1, 3], decodeOne)).toEqual({ ok: true, value: [3, 1, 3] });
  });
});
