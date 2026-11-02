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

import { fireEvent, within } from '@testing-library/dom';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { buildTable, TableHarness } from '../../testing/table-harness';

describe('RelationsCellHandler', () => {
  const translations = { 'js.work_packages.table.relations_button': 'Relations in %{column} for %{work_package}' };
  let harness:TableHarness;

  const mount = async (keyboardNavigationEnabled:boolean) => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', { id: 'follows', relationType: 'follows' }],
      translations,
      configuration: { keyboardNavigationEnabled },
    });
    await harness.render();
    const service = harness.injector.get(WorkPackageViewRelationColumnsService);
    return {
      setExpandFor: vi.spyOn(service, 'setExpandFor'),
      collapse: vi.spyOn(service, 'collapse'),
    };
  };

  afterEach(() => harness.destroy());

  it('toggles once on a pointer click', async () => {
    const spies = await mount(true);
    const button = within(harness.row('1')).getByRole('button', { name: 'Relations in follows for #1' });

    fireEvent.click(button);

    expect(spies.setExpandFor).toHaveBeenCalledTimes(1);
    expect(spies.collapse).not.toHaveBeenCalled();
  });

  it('toggles once for Enter keydown followed by its synthesized click', async () => {
    const spies = await mount(true);
    const button = within(harness.row('1')).getByRole('button', { name: 'Relations in follows for #1' });

    fireEvent.keyDown(button, { key: 'Enter' });
    fireEvent.click(button);

    expect(spies.setExpandFor).toHaveBeenCalledTimes(1);
    expect(spies.collapse).not.toHaveBeenCalled();
  });

  it('still toggles the disabled-capability span on Enter keydown', async () => {
    const spies = await mount(false);
    const indicator = harness.row('1').querySelector<HTMLElement>('.wp-table--relation-indicator')!;

    fireEvent.keyDown(indicator, { key: 'Enter' });

    expect(spies.setExpandFor).toHaveBeenCalledTimes(1);
  });
});
