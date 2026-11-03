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

import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { UiStateLinkBuilder } from '../../builders/ui-state-link-builder';
import { fireEvent } from '@testing-library/dom';
import { buildTable, TableHarness } from '../../testing/table-harness';

describe('WorkPackageStateLinksHandler', () => {
  let table:TableHarness;
  let builder:UiStateLinkBuilder;

  beforeEach(async () => {
    table = buildTable({ workPackages: [{ id: '42' }], productionMarkup: true });
    await table.render();
    builder = new UiStateLinkBuilder(
      table.injector.get(KeepTabService),
      table.injector.get(CurrentProjectService),
      table.injector.get(PathHelperService),
      table.injector.get(UrlParamsService),
    );
  });

  afterEach(async () => {
    await table.destroy();
  });

  it.each(['split', 'show'])('emits the %s route with the numeric work package identity', (state) => {
    const received = vi.fn();
    table.outputs.stateLinkClicked.subscribe(received);
    const link = state === 'split'
      ? builder.linkToDetails('42', 'Details', 'Open', 'PROJ-7')
      : builder.linkToShow('42', 'Show', 'Open', 'PROJ-7');
    table.row('42').firstElementChild!.appendChild(link);

    expect(fireEvent.click(link)).toBe(false);
    expect(received).toHaveBeenCalledExactlyOnceWith({ workPackageId: '42', requestedState: state });
  });

  it('leaves unsupported dataset states to normal link processing', () => {
    const received = vi.fn();
    table.outputs.stateLinkClicked.subscribe(received);
    const link = builder.linkToShow('42', 'Show', 'Open');
    table.row('42').firstElementChild!.appendChild(link);
    link.dataset.wpState = 'unsupported';
    link.removeAttribute('href');

    expect(fireEvent.click(link)).toBe(true);
    expect(received).not.toHaveBeenCalled();
  });
});
