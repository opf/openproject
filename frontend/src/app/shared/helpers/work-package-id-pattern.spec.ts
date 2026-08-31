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

import { formatWorkPackageId, isSemanticWorkPackageId } from './work-package-id-pattern';

describe('isSemanticWorkPackageId', () => {
  it('returns true for semantic identifiers', () => {
    expect(isSemanticWorkPackageId('PROJ-42')).toBe(true);
  });

  it('returns false for numeric identifiers', () => {
    expect(isSemanticWorkPackageId('42')).toBe(false);
  });

  it('returns false for empty input', () => {
    expect(isSemanticWorkPackageId('')).toBe(false);
  });
});

describe('formatWorkPackageId', () => {
  it('returns semantic identifiers as-is (no prefix)', () => {
    expect(formatWorkPackageId('PROJ-42')).toBe('PROJ-42');
  });

  it('prefixes numeric identifiers with #', () => {
    expect(formatWorkPackageId('42')).toBe('#42');
  });

  it('returns empty string for empty input', () => {
    expect(formatWorkPackageId('')).toBe('');
  });
});
