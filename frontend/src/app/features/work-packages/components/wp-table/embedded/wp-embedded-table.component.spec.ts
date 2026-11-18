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

import { NEVER, Subject } from 'rxjs';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { LatestOnly } from 'core-app/features/work-packages/routing/wp-view-base/latest-only';
import { WorkPackageEmbeddedTableComponent } from 'core-app/features/work-packages/components/wp-table/embedded/wp-embedded-table.component';

function fromPrototype<T extends object>(prototype:T, properties:Record<string, unknown>):T {
  return Object.assign(Object.create(prototype) as T, properties);
}

function queryWithResults(name:string):QueryResource {
  return { name, results: { name } } as unknown as QueryResource;
}

describe('loads of an embedded table that do not come from a refresh', () => {
  let responses:Subject<QueryResource>[];
  let updateQuerySpace:ReturnType<typeof vi.fn>;
  let embedded:WorkPackageEmbeddedTableComponent;
  const request = () => {
    const response = new Subject<QueryResource>();
    responses.push(response);
    return response;
  };
  const respond = (index:number, query:QueryResource) => {
    responses[index].next(query);
    responses[index].complete();
  };
  const current = queryWithResults('current');
  const older = queryWithResults('older');
  const newer = queryWithResults('newer');

  beforeEach(() => {
    responses = [];
    updateQuerySpace = vi.fn();
    embedded = fromPrototype(WorkPackageEmbeddedTableComponent.prototype, {
      reloads: new LatestOnly(),
      querySpace: { query: { value: current }, initialized: { values$: () => NEVER } },
      configuration: { projectContext: false, tableVisible: true },
      loadingIndicatorService: { indicator: () => ({ promise: undefined }) },
      queryProps: {},
      wpTablePagination: { paginationObject: {} },
      urlParamsHelper: { buildV3GetQueryFromQueryResource: () => ({}) },
      wpListService: { loadQueryFromExisting: request },
      apiv3Service: { queries: { find: request } },
      wpStatesInitialization: { clearStates: vi.fn(), initializeFromQuery: vi.fn(), updateQuerySpace },
      onQueryLoaded: { emit: vi.fn() },
      onError: { emit: vi.fn() },
      cdRef: { markForCheck: vi.fn() },
      I18n: { t: (key:string) => key },
    });
  });

  it('give way to a later refresh when loading the query', async () => {
    const loading = embedded.loadQuery(false, false);
    embedded.refresh(false, false);
    expect(responses[0].observed).toBe(false);

    respond(1, newer);
    respond(0, older);
    await loading;

    expect(updateQuerySpace).toHaveBeenCalledExactlyOnceWith(newer, newer.results);
  });

  it('resolve with the loaded query', async () => {
    const loading = embedded.loadQuery(false, false);

    respond(0, newer);

    expect(await loading).toBe(newer);
  });

  it('give way to a later refresh when changing the page', async () => {
    embedded.reloadPage(current);
    embedded.refresh(false, false);
    expect(responses[0].observed).toBe(false);

    respond(1, newer);
    respond(0, older);

    await vi.waitFor(() => expect(updateQuerySpace).toHaveBeenCalledExactlyOnceWith(newer, newer.results));
  });
});
