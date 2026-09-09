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

import { BatchSelection, selectionKey } from './batch-selection';

describe('BatchSelection', () => {
  let selection:BatchSelection;

  beforeEach(() => {
    selection = new BatchSelection();
  });

  it('starts empty with no anchor', () => {
    expect(selection.size).toBe(0);
    expect(selection.anchor).toBeNull();
  });

  it('replaces the batch and establishes the anchor', () => {
    selection.replace({ type: 'work_package', id: '1' }, 'sprint:7');
    selection.replace({ type: 'work_package', id: '2' }, 'sprint:7');

    expect(selection.items().map((entry) => entry.id)).toEqual(['2']);
    expect(selection.anchor).toEqual({ type: 'work_package', id: '2', listKey: 'sprint:7' });
  });

  it('re-bases the anchor when toggling on', () => {
    selection.replace({ type: 'work_package', id: '1' }, 'sprint:7');
    selection.toggle({ type: 'work_package', id: '2' }, 'sprint:7');

    expect(selection.items().map((entry) => entry.id)).toEqual(['1', '2']);
    expect(selection.anchor).toEqual({ type: 'work_package', id: '2', listKey: 'sprint:7' });
  });

  // The anchor deliberately survives its own deselection: the next Shift
  // gesture still measures its range from the card the user last touched.
  it('re-bases the anchor when toggling off', () => {
    selection.replace({ type: 'work_package', id: '1' }, 'sprint:7');
    selection.toggle({ type: 'work_package', id: '1' }, 'sprint:7');

    expect(selection.size).toBe(0);
    expect(selection.anchor).toEqual({ type: 'work_package', id: '1', listKey: 'sprint:7' });
  });

  it('resizes a range and preserves the anchor', () => {
    selection.replace({ type: 'work_package', id: '1' }, 'sprint:7');
    selection.range([{ type: 'work_package', id: '1' }, { type: 'work_package', id: '2' }, { type: 'work_package', id: '3' }]);
    selection.range([{ type: 'work_package', id: '1' }, { type: 'work_package', id: '2' }]);

    expect(selection.items().map((entry) => entry.id)).toEqual(['1', '2']);
    expect(selection.anchor).toEqual({ type: 'work_package', id: '1', listKey: 'sprint:7' });
  });

  describe('range sessions', () => {
    const wp = (id:string) => ({ type: 'work_package', id });
    const ids = () => selection.items().map((entry) => entry.id).sort();

    beforeEach(() => {
      selection.replace(wp('1'), 'sprint:7');
      selection.toggle(wp('3'), 'sprint:7');
    });

    it('preserves independent selections while extending, shrinking and reversing', () => {
      selection.range(['3', '4', '5'].map(wp));
      expect(ids()).toEqual(['1', '3', '4', '5']);
      selection.range(['3', '4'].map(wp));
      expect(ids()).toEqual(['1', '3', '4']);
      selection.range(['2', '3'].map(wp));
      expect(ids()).toEqual(['1', '2', '3']);
    });

    it('preserves baseline members even when they overlap a previous range', () => {
      selection.range(['1', '2', '3'].map(wp));
      selection.range(['3', '4'].map(wp));
      expect(ids()).toEqual(['1', '3', '4']);
    });

    it('starts a new baseline after toggling off the anchor', () => {
      selection.range(['3', '4'].map(wp));
      selection.toggle(wp('3'), 'sprint:7');
      selection.range(['2', '3'].map(wp));
      expect(ids()).toEqual(['1', '2', '3', '4']);
      expect(selection.anchor?.id).toBe('3');
    });

    it.each(['replace', 'clear', 'selectAll'] as const)('ends the session on %s', (operation) => {
      selection.range(['3', '4'].map(wp));
      if (operation === 'replace') {
        selection.replace(wp('5'), 'sprint:7');
      } else if (operation === 'selectAll') {
        selection.selectAll([wp('5')], { ...wp('5'), listKey: 'sprint:7' });
      } else {
        selection.clear();
      }
      selection.range(['5', '6'].map(wp));
      expect(ids()).toEqual(['5', '6']);
    });

    it('narrows and reverses a selection made with select-all', () => {
      selection.selectAll(['1', '2', '3', '4', '5'].map(wp), { ...wp('3'), listKey: 'sprint:7' });
      selection.range(['3', '4'].map(wp));
      expect(ids()).toEqual(['3', '4']);
      selection.range(['2', '3'].map(wp));
      expect(ids()).toEqual(['2', '3']);
    });

    it('starts a fresh baseline when toggling after select-all', () => {
      selection.selectAll(['1', '2', '3', '4'].map(wp), { ...wp('3'), listKey: 'sprint:7' });
      selection.toggle(wp('2'), 'sprint:7');
      selection.range(['2', '3'].map(wp));
      expect(ids()).toEqual(['1', '2', '3', '4']);
    });

    it('does not restore pruned baseline members', () => {
      selection.range(['3', '4'].map(wp));
      selection.prune(new Set(['3', '4', '5'].map((id) => selectionKey(wp(id)))));
      selection.range(['3', '5'].map(wp));
      expect(ids()).toEqual(['3', '5']);
    });

    it('keeps the session through unchanged reconciliation', () => {
      selection.range(['3', '4', '5'].map(wp));
      selection.prune(new Set(['1', '3', '4', '5'].map((id) => selectionKey(wp(id)))));
      selection.rebindAnchor('sprint:7');
      selection.range(['3', '4'].map(wp));
      expect(ids()).toEqual(['1', '3', '4']);
    });

    it('ends the session when the anchor moves to another list', () => {
      selection.range(['3', '4'].map(wp));
      selection.rebindAnchor('sprint:8');
      selection.range(['3', '5'].map(wp));
      expect(ids()).toEqual(['1', '3', '4', '5']);
    });
  });

  it('selects all with an explicit anchor', () => {
    selection.selectAll([{ type: 'work_package', id: '3' }, { type: 'work_package', id: '1' }, { type: 'work_package', id: '2' }], { type: 'work_package', id: '2', listKey: 'sprint:7' });

    expect(selection.items().map((entry) => entry.id)).toEqual(['3', '1', '2']);
    expect(selection.anchor).toEqual({ type: 'work_package', id: '2', listKey: 'sprint:7' });
  });

  it('clears the batch and the anchor', () => {
    selection.replace({ type: 'work_package', id: '1' }, 'sprint:7');
    selection.clear();

    expect(selection.size).toBe(0);
    expect(selection.anchor).toBeNull();
  });

  it('prunes ids that are no longer live and reports the change', () => {
    selection.replace({ type: 'work_package', id: '1' }, 'sprint:7');
    selection.toggle({ type: 'work_package', id: '2' }, 'sprint:7');

    expect(selection.prune(new Set([selectionKey({ type: 'work_package', id: '1' })]))).toBe(true);
    expect(selection.items().map((entry) => entry.id)).toEqual(['1']);
    expect(selection.prune(new Set([selectionKey({ type: 'work_package', id: '1' })]))).toBe(false);
  });

  it('drops an anchor whose card is gone', () => {
    selection.replace({ type: 'work_package', id: '1' }, 'sprint:7');
    selection.prune(new Set<string>());

    expect(selection.anchor).toBeNull();
  });

  it('reports membership without exposing mutable state', () => {
    selection.replace({ type: 'work_package', id: '1' }, 'sprint:7');

    expect(selection.has({ type: 'work_package', id: '1' })).toBe(true);
    expect(selection.has({ type: 'work_package', id: '2' })).toBe(false);
  });

  describe('composite identity', () => {
    // Ids are unique per table, not per root: a section and a custom field
    // can both be id 5, and a nested topology puts them under one root.
    it('keeps items of different types that share an id apart', () => {
      selection.toggle({ type: 'section', id: '5' }, 'sections');
      selection.toggle({ type: 'custom_field', id: '5' }, 'custom_field:5');

      expect(selection.size).toBe(2);
      expect(selection.has({ type: 'section', id: '5' })).toBe(true);
      expect(selection.has({ type: 'custom_field', id: '5' })).toBe(true);
      expect(selection.has({ type: 'work_package', id: '5' })).toBe(false);
    });

    it('prunes by composite key, not by bare id', () => {
      selection.toggle({ type: 'custom_field', id: '5' }, 'custom_field:5');

      // The id survives — under a different type, which is a different item.
      selection.prune(new Set([selectionKey({ type: 'section', id: '5' })]));

      expect(selection.size).toBe(0);
    });

    it('drops an anchor whose type no longer exists even when the id survives', () => {
      selection.replace({ type: 'custom_field', id: '5' }, 'custom_field:5');

      selection.prune(new Set([selectionKey({ type: 'section', id: '5' })]));

      expect(selection.anchor).toBeNull();
    });

    it('builds a key that no type or id can forge a collision in', () => {
      expect(selectionKey({ type: 'a', id: 'b' }))
        .not.toEqual(selectionKey({ type: 'a\u001Fb', id: '' }));
    });
  });

  describe('#rebindAnchor', () => {
    // A card can be moved to another list while staying the anchor, so the
    // caller re-derives the key and hands it back.
    it('points the anchor at a different list without disturbing membership', () => {
      selection.replace({ type: 'work_package', id: '7' }, 'sprint:1');

      selection.rebindAnchor('sprint:2');

      expect(selection.anchor).toEqual({ type: 'work_package', id: '7', listKey: 'sprint:2' });
      expect(selection.items().map((entry) => entry.id)).toEqual(['7']);
    });

    it('does nothing when there is no anchor', () => {
      selection.rebindAnchor('sprint:2');

      expect(selection.anchor).toBeNull();
    });
  });
});
