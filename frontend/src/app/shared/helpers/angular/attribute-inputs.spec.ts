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

import {
  booleanAttributeOr,
  jsonAttribute,
  numberAttributeOr,
  optionalStringAttribute,
  stringAttribute,
} from './attribute-inputs';

describe('attribute input transforms', () => {
  describe('booleanAttributeOr', () => {
    it('falls back when the attribute is removed', () => {
      expect(booleanAttributeOr(true)(null)).toBe(true);
      expect(booleanAttributeOr(false)(undefined)).toBe(false);
    });

    it('treats a bare attribute as true and "false" as false', () => {
      expect(booleanAttributeOr(false)('')).toBe(true);
      expect(booleanAttributeOr(true)('')).toBe(true);
      expect(booleanAttributeOr(true)('false')).toBe(false);
    });

    it('passes typed booleans through', () => {
      expect(booleanAttributeOr(true)(false)).toBe(false);
      expect(booleanAttributeOr(false)(true)).toBe(true);
    });
  });

  describe('numberAttributeOr', () => {
    it('parses numeric strings and falls back on null', () => {
      expect(numberAttributeOr(0)('3')).toBe(3);
      expect(numberAttributeOr(0)(null)).toBe(0);
      expect(numberAttributeOr(7)(undefined)).toBe(7);
      expect(numberAttributeOr(0)(5)).toBe(5);
      expect(numberAttributeOr(7)('abc')).toBe(7);
    });
  });

  describe('stringAttribute', () => {
    it('returns the value or the fallback', () => {
      expect(stringAttribute('')(null)).toBe('');
      expect(stringAttribute('')('x')).toBe('x');
      expect(stringAttribute('d')(undefined)).toBe('d');
    });
  });

  describe('optionalStringAttribute', () => {
    it('maps a removed attribute to undefined and passes strings through', () => {
      expect(optionalStringAttribute()(null)).toBeUndefined();
      expect(optionalStringAttribute()(undefined)).toBeUndefined();
      expect(optionalStringAttribute()('x')).toBe('x');
    });
  });

  describe('jsonAttribute', () => {
    const transform = jsonAttribute<{ id:number }|null>(null);

    it('parses JSON strings', () => {
      expect(transform('{"id":1}')).toEqual({ id: 1 });
    });

    it('passes typed values through by identity', () => {
      const value = { id: 2 };
      expect(transform(value)).toBe(value);
    });

    it('falls back on null', () => {
      expect(transform(null)).toBeNull();
    });

    it('throws naming the malformed value', () => {
      expect(() => transform('{oops')).toThrow(Error);
      expect(() => transform('{oops')).toThrow('{oops');
    });
  });
});
