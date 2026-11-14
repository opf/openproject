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

import { within } from '@testing-library/dom';
import { buildTable, TableHarness, TableHarnessOptions } from '../testing/table-harness';

describe('CellBuilder display fields', () => {
  let harness:TableHarness;

  const renderTable = async (options:Partial<TableHarnessOptions> = {}) => {
    harness = buildTable({
      workPackages: [{ id: '1', subject: 'Report record' }],
      translations: { 'js.inplace.button_edit': '%{attribute}: Edit' },
      ...options,
    });
    await harness.render();
  };

  const row = () => within(harness.row('1'));

  afterEach(() => harness.destroy());

  describe('with an editable field', () => {
    beforeEach(() => renderTable({ editing: {} }));

    it('labels the field with its edit action', () => {
      expect(row().getByLabelText('subject Report record: Edit')).toBeInTheDocument();
    });

    it('shows the text cursor', () => {
      expect(getComputedStyle(row().getByLabelText('subject Report record: Edit')).cursor).toBe('text');
    });
  });

  describe('with a field the user cannot edit', () => {
    beforeEach(() => renderTable());

    it('labels the field without an edit action', () => {
      expect(row().getByLabelText('subject Report record')).toBeInTheDocument();
    });

    it('shows the not-allowed cursor', () => {
      expect(getComputedStyle(row().getByLabelText('subject Report record')).cursor).toBe('not-allowed');
    });
  });

  describe('with inline editing disabled for the table', () => {
    beforeEach(() => renderTable({ editing: {}, configuration: { inlineEditEnabled: false } }));

    it('labels the field without an edit action', () => {
      expect(row().getByLabelText('subject Report record')).toBeInTheDocument();
      expect(row().queryByLabelText(/: Edit$/)).not.toBeInTheDocument();
    });

    it('shows neither an edit nor a not-allowed cursor', () => {
      const { cursor } = getComputedStyle(row().getByLabelText('subject Report record'));

      expect(cursor).not.toBe('text');
      expect(cursor).not.toBe('not-allowed');
    });
  });
});
