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

import {
  anchoredOccurrence,
  occurrenceRangeIds,
  sameOccurrence,
  selectAllAnchor,
  selectableOccurrences,
} from './rendered-occurrences';

describe('rendered-occurrences', () => {
  const row = (id:string, classIdentifier = `wp-row-${id}`, hidden = false):RenderedWorkPackage => ({
    workPackageId: id, classIdentifier, hidden,
  });
  const header:RenderedWorkPackage = { workPackageId: null, classIdentifier: 'group-1', hidden: false };
  const anchorAt = (id:string, occurrenceKey:string) => ({
    type: 'work_package', id, listKey: 'view', occurrenceKey,
  });
  const rows = [row('1'), row('2'), row('3'), row('4')];

  describe('sameOccurrence', () => {
    it('needs both id and occurrence to match', () => {
      expect(sameOccurrence(row('2'), row('2'))).toBe(true);
      expect(sameOccurrence(row('2'), row('2', 'relation-2'))).toBe(false);
      expect(sameOccurrence(row('2'), row('3', 'wp-row-2'))).toBe(false);
    });
  });

  describe('selectableOccurrences', () => {
    it('drops rows without a work package', () => {
      expect(selectableOccurrences([header, row('1'), header])).toEqual([row('1')]);
    });
  });

  describe('anchoredOccurrence', () => {
    it('finds the exact occurrence among duplicates of one work package', () => {
      const rendered = [row('1'), row('2'), row('2', 'relation-2'), row('3')];
      expect(anchoredOccurrence(rendered, anchorAt('2', 'relation-2'))).toBe(rendered[2]);
    });

    it('does not let another occurrence of the same id stand in', () => {
      expect(anchoredOccurrence(rows, anchorAt('2', 'relation-2'))).toBeUndefined();
    });

    it('resolves nothing for a missing anchor or one without an occurrence', () => {
      expect(anchoredOccurrence(rows, null)).toBeUndefined();
      expect(anchoredOccurrence(rows, { type: 'work_package', id: '2', listKey: 'view' })).toBeUndefined();
    });
  });

  describe('occurrenceRangeIds', () => {
    it('spans forward and backward in rendered order', () => {
      expect(occurrenceRangeIds(rows, anchorAt('2', 'wp-row-2'), rows[3])).toEqual(['2', '3', '4']);
      expect(occurrenceRangeIds(rows, anchorAt('3', 'wp-row-3'), rows[0])).toEqual(['1', '2', '3']);
    });

    it('includes hidden rows and skips group headers', () => {
      const rendered = [row('1'), header, row('2', 'wp-row-2', true), row('3')];
      expect(occurrenceRangeIds(rendered, anchorAt('1', 'wp-row-1'), rendered[3])).toEqual(['1', '2', '3']);
    });

    it('repeats an id rendered twice inside the span', () => {
      const rendered = [row('1'), row('2'), row('2', 'relation-2'), row('3')];
      expect(occurrenceRangeIds(rendered, anchorAt('1', 'wp-row-1'), rendered[3])).toEqual(['1', '2', '2', '3']);
    });

    it('yields null when the anchor is absent or not rendered', () => {
      expect(occurrenceRangeIds(rows, null, rows[3])).toBeNull();
      expect(occurrenceRangeIds(rows, anchorAt('2', 'relation-2'), rows[3])).toBeNull();
    });

    it('yields null when the target row is not rendered', () => {
      expect(occurrenceRangeIds(rows, anchorAt('2', 'wp-row-2'), row('9'))).toBeNull();
    });
  });

  describe('selectAllAnchor', () => {
    it('prefers the requested occurrence when it is selectable', () => {
      expect(selectAllAnchor(rows, rows[2])).toBe(rows[2]);
    });

    it('falls back to the first selectable occurrence', () => {
      expect(selectAllAnchor(rows, row('4', 'missing'))).toBe(rows[0]);
      expect(selectAllAnchor(rows)).toBe(rows[0]);
    });

    it('has nothing to anchor in an empty list', () => {
      expect(selectAllAnchor([])).toBeUndefined();
    });
  });
});
