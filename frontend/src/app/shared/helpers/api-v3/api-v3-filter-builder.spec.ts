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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { describe, expect, it } from 'vitest';
import {
  ApiV3FilterBuilder,
  FalseValue,
  TrueValue,
} from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

// Exercises the object-iteration helpers migrated off lodash (Object.entries
// over the filter map): the `filters` getter and `toFilterObject`.
describe('ApiV3FilterBuilder', () => {
  describe('add() and the filters getter', () => {
    it('serialises each entry of the filter map to a single-key object', () => {
      const builder = new ApiV3FilterBuilder()
        .add('status', '=', ['1'])
        .add('subject', '~', ['foo']);

      expect(builder.filters).toEqual([
        { status: { operator: '=', values: ['1'] } },
        { subject: { operator: '~', values: ['foo'] } },
      ]);
    });

    it('preserves insertion order of the filter map', () => {
      const builder = new ApiV3FilterBuilder()
        .add('c', '=', ['3'])
        .add('a', '=', ['1'])
        .add('b', '=', ['2']);

      expect(builder.filters.map((f) => Object.keys(f)[0])).toEqual(['c', 'a', 'b']);
    });

    it('maps boolean filter values to the lodash truthy/falsy sentinels', () => {
      const builder = new ApiV3FilterBuilder()
        .add('open', '=', true)
        .add('closed', '=', false);

      expect(builder.filters).toEqual([
        { open: { operator: '=', values: TrueValue } },
        { closed: { operator: '=', values: FalseValue } },
      ]);
    });

    it('returns an empty array when no filters were added', () => {
      expect(new ApiV3FilterBuilder().filters).toEqual([]);
    });
  });

  describe('toFilterObject', () => {
    it('flattens an array of single-key filters into one map', () => {
      const map = ApiV3FilterBuilder.toFilterObject([
        { status: { operator: '=', values: ['1'] } },
        { subject: { operator: '~', values: ['foo'] } },
      ]);

      expect(map).toEqual({
        status: { operator: '=', values: ['1'] },
        subject: { operator: '~', values: ['foo'] },
      });
    });

    it('iterates every key of a multi-key filter item', () => {
      const map = ApiV3FilterBuilder.toFilterObject([
        {
          status: { operator: '=', values: ['1'] },
          subject: { operator: '~', values: ['foo'] },
        },
      ]);

      expect(Object.keys(map)).toEqual(['status', 'subject']);
    });

    it('lets a later duplicate key overwrite an earlier one', () => {
      const map = ApiV3FilterBuilder.toFilterObject([
        { status: { operator: '=', values: ['1'] } },
        { status: { operator: '!', values: ['2'] } },
      ]);

      expect(map.status).toEqual({ operator: '!', values: ['2'] });
    });
  });

  describe('round trips', () => {
    it('fromFilterObject reconstructs an equivalent builder', () => {
      const original = new ApiV3FilterBuilder()
        .add('status', '=', ['1'])
        .add('subject', '~', ['foo']);

      const rebuilt = ApiV3FilterBuilder.fromFilterObject(
        ApiV3FilterBuilder.toFilterObject(original.filters),
      );

      expect(rebuilt.filters).toEqual(original.filters);
    });

    it('clone produces an independent copy', () => {
      const original = new ApiV3FilterBuilder().add('status', '=', ['1']);
      const copy = original.clone();
      copy.add('subject', '~', ['foo']);

      expect(original.filters).toHaveLength(1);
      expect(copy.filters).toHaveLength(2);
    });
  });
});
