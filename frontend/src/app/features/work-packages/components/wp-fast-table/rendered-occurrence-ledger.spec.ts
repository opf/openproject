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

import { describe, expect, it } from 'vitest';
import {
  ancestorOccurrenceKey,
  DraftOccurrence,
  groupOccurrenceKey,
  OccurrenceKey,
  placeholderOccurrenceKey,
  relationOccurrenceKey,
  RenderedOccurrenceLedger,
  wpOccurrenceKey,
} from './rendered-occurrence-ledger';

function draftOccurrence(key:OccurrenceKey, overrides:Partial<DraftOccurrence> = {}):DraftOccurrence {
  return {
    key,
    classIdentifier: 'wp-row-1',
    workPackageId: '1',
    renderType: 'primary',
    hidden: false,
    element: null,
    additionalClasses: [],
    workPackage: null,
    ...overrides,
  };
}

function commitKeys(ledger:RenderedOccurrenceLedger, ...occurrences:DraftOccurrence[]) {
  const draft = ledger.beginRender();
  occurrences.forEach((occ) => draft.append(occ));
  ledger.commit(draft);
}

describe('RenderedOccurrenceLedger', () => {
  it('keeps registration order and round-trips keyAt and indexOfKey', () => {
    const ledger = new RenderedOccurrenceLedger();
    const keys = [wpOccurrenceKey('1'), wpOccurrenceKey('2'), wpOccurrenceKey('3')];
    commitKeys(ledger, ...keys.map((key, i) => draftOccurrence(key, { workPackageId: `${i + 1}` })));

    expect(ledger.size).toBe(3);
    keys.forEach((key, index) => {
      expect(ledger.indexOfKey(key)).toBe(index);
      expect(ledger.keyAt(index)).toBe(key);
    });
    expect(ledger.keyAt(3)).toBeUndefined();
    expect(ledger.indexOfKey('unknown')).toBe(-1);
  });

  it('inserts a splice immediately after the target key', () => {
    const ledger = new RenderedOccurrenceLedger();
    const draft = ledger.beginRender();
    draft.append(draftOccurrence('a'));
    draft.append(draftOccurrence('b'));
    draft.spliceAfter('a', draftOccurrence('x'));
    ledger.commit(draft);

    expect([0, 1, 2].map((i) => ledger.keyAt(i))).toEqual(['a', 'x', 'b']);
  });

  it('lands a second splice after the same key between the target and the first splice', () => {
    const ledger = new RenderedOccurrenceLedger();
    const draft = ledger.beginRender();
    draft.append(draftOccurrence('a'));
    draft.append(draftOccurrence('b'));
    draft.spliceAfter('a', draftOccurrence('x'));
    draft.spliceAfter('a', draftOccurrence('y'));
    ledger.commit(draft);

    expect([0, 1, 2, 3].map((i) => ledger.keyAt(i))).toEqual(['a', 'y', 'x', 'b']);
    expect(draft.occurrences.map((o) => o.key)).toEqual(['a', 'y', 'x', 'b']);
  });

  it('throws in dev mode when splicing after an unknown key', () => {
    const draft = new RenderedOccurrenceLedger().beginRender();
    draft.append(draftOccurrence('a'));

    expect(() => draft.spliceAfter('missing', draftOccurrence('x'))).toThrow();
  });

  it('throws in dev mode when a key is registered twice', () => {
    const draft = new RenderedOccurrenceLedger().beginRender();
    draft.append(draftOccurrence('a'));

    expect(() => draft.append(draftOccurrence('a'))).toThrow();
    expect(() => draft.spliceAfter('a', draftOccurrence('a'))).toThrow();
  });

  it('keeps duplicate occurrences of one work package under distinct keys', () => {
    const ledger = new RenderedOccurrenceLedger();
    commitKeys(
      ledger,
      draftOccurrence(wpOccurrenceKey('7'), { workPackageId: '7' }),
      draftOccurrence(ancestorOccurrenceKey('7'), { workPackageId: '7' }),
      draftOccurrence(wpOccurrenceKey('8'), { workPackageId: '8' }),
    );

    expect(ledger.byWorkPackageId('7').map((o) => o.key)).toEqual([wpOccurrenceKey('7'), ancestorOccurrenceKey('7')]);
    expect(ledger.byWorkPackageId('missing')).toEqual([]);
  });

  it('keeps two relation occurrences that share one bridge classIdentifier', () => {
    const ledger = new RenderedOccurrenceLedger();
    const relation = { label: 'Follows', columnId: 'relations', relationType: 'toType' as const };
    const first = relationOccurrenceKey('toType', '1', '2');
    const second = relationOccurrenceKey('toType', '1', '3');
    commitKeys(
      ledger,
      draftOccurrence(first, { classIdentifier: 'wp-row-1-bridge', workPackageId: '2', renderType: 'relations', relation }),
      draftOccurrence(second, { classIdentifier: 'wp-row-1-bridge', workPackageId: '3', renderType: 'relations', relation }),
    );

    expect(first).not.toBe(second);
    expect(ledger.byKey(first)?.workPackageId).toBe('2');
    expect(ledger.byKey(second)?.workPackageId).toBe('3');
    expect(ledger.snapshot().map((s) => s.classIdentifier)).toEqual(['wp-row-1-bridge', 'wp-row-1-bridge']);
  });

  it('mints distinct keys for the group header and sums of one index', () => {
    expect(groupOccurrenceKey(2, 'header')).not.toBe(groupOccurrenceKey(2, 'sums'));
    expect(groupOccurrenceKey(2, 'header')).not.toBe(groupOccurrenceKey(3, 'header'));

    const ledger = new RenderedOccurrenceLedger();
    commitKeys(
      ledger,
      draftOccurrence(groupOccurrenceKey(2, 'header'), { workPackageId: null }),
      draftOccurrence(groupOccurrenceKey(2, 'sums'), { workPackageId: null }),
    );
    expect(ledger.size).toBe(2);
  });

  it('mints keys of different kinds that never collide', () => {
    const keys = [
      wpOccurrenceKey('1'),
      ancestorOccurrenceKey('1'),
      relationOccurrenceKey('ofType', '1', '2'),
      relationOccurrenceKey('children', '1', '2'),
      groupOccurrenceKey(1, 'header'),
      placeholderOccurrenceKey(),
    ];
    expect(new Set(keys).size).toBe(keys.length);
  });

  it('patches hidden flags with setHidden and bumps generation', () => {
    const ledger = new RenderedOccurrenceLedger();
    commitKeys(ledger, draftOccurrence('a'), draftOccurrence('b'), draftOccurrence('c'));
    const before = ledger.generation;

    ledger.setHidden(new Map([['a', true], ['c', true]]));

    expect(ledger.byKey('a')?.hidden).toBe(true);
    expect(ledger.byKey('b')?.hidden).toBe(false);
    expect(ledger.byKey('c')?.hidden).toBe(true);
    expect(ledger.generation).toBe(before + 1);

    ledger.setHidden(new Map([['a', false]]));
    expect(ledger.byKey('a')?.hidden).toBe(false);
    expect(ledger.generation).toBe(before + 2);
  });

  it('never mutates a snapshot taken before setHidden', () => {
    const ledger = new RenderedOccurrenceLedger();
    commitKeys(ledger, draftOccurrence('a'));
    const snapshot = ledger.snapshot();

    ledger.setHidden(new Map([['a', true]]));

    expect(snapshot[0].hidden).toBe(false);
    expect(ledger.snapshot()[0].hidden).toBe(true);
  });

  it('returns a fresh snapshot with classIdentifier, workPackageId and hidden in order', () => {
    const ledger = new RenderedOccurrenceLedger();
    commitKeys(
      ledger,
      draftOccurrence('a', { classIdentifier: 'wp-row-1', workPackageId: '1' }),
      draftOccurrence('b', { classIdentifier: 'group-header-0', workPackageId: null, hidden: true }),
    );

    const first = ledger.snapshot();
    expect(first).toEqual([
      { classIdentifier: 'wp-row-1', workPackageId: '1', hidden: false },
      { classIdentifier: 'group-header-0', workPackageId: null, hidden: true },
    ]);
    expect(ledger.snapshot()).not.toBe(first);
    first.pop();
    expect(ledger.snapshot()).toHaveLength(2);
  });

  it('replaces the element without changing order, hidden or generation', () => {
    const ledger = new RenderedOccurrenceLedger();
    const original = document.createElement('tr');
    const replacement = document.createElement('tr');
    commitKeys(ledger, draftOccurrence('a', { element: original }), draftOccurrence('b'));
    ledger.setHidden(new Map([['a', true]]));
    const generation = ledger.generation;

    ledger.replaceElement('a', replacement);

    expect(ledger.byKey('a')?.element).toBe(replacement);
    expect(ledger.byElement(replacement)?.key).toBe('a');
    expect(ledger.byElement(original)).toBeUndefined();
    expect(ledger.byKey('a')?.hidden).toBe(true);
    expect(ledger.indexOfKey('a')).toBe(0);
    expect(ledger.generation).toBe(generation);
  });

  it('looks up occurrences by element', () => {
    const ledger = new RenderedOccurrenceLedger();
    const el = document.createElement('tr');
    commitKeys(ledger, draftOccurrence('a', { element: el }), draftOccurrence('b'));

    expect(ledger.byElement(el)?.key).toBe('a');
    expect(ledger.byElement(document.createElement('tr'))).toBeUndefined();
  });

  it('does not expose an uncommitted draft', () => {
    const ledger = new RenderedOccurrenceLedger();
    commitKeys(ledger, draftOccurrence('a'));
    const generation = ledger.generation;

    const draft = ledger.beginRender();
    draft.append(draftOccurrence('z'));

    expect(ledger.size).toBe(1);
    expect(ledger.byKey('z')).toBeUndefined();
    expect(ledger.keyAt(0)).toBe('a');
    expect(ledger.snapshot()).toHaveLength(1);
    expect(ledger.generation).toBe(generation);
  });

  it('replaces contents wholesale on commit and bumps generation', () => {
    const ledger = new RenderedOccurrenceLedger();
    commitKeys(ledger, draftOccurrence('a'), draftOccurrence('b'));
    const generation = ledger.generation;
    const snapshot = ledger.snapshot();

    commitKeys(ledger, draftOccurrence('c'));

    expect(ledger.byKey('a')).toBeUndefined();
    expect(ledger.size).toBe(1);
    expect(ledger.generation).toBe(generation + 1);
    expect(snapshot).toHaveLength(2);
  });

  it('reports withTimeline from the draft', () => {
    const ledger = new RenderedOccurrenceLedger();
    expect(ledger.beginRender().withTimeline).toBe(false);
    expect(ledger.beginRender(true).withTimeline).toBe(true);
  });
});
