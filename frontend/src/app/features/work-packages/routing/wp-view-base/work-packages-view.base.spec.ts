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

import { Subject } from 'rxjs';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { LatestOnly } from 'core-app/features/work-packages/routing/wp-view-base/latest-only';
import { PartitionedQuerySpacePageComponent } from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import { IFCViewerPageComponent } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-viewer-page.component';
import { WorkPackageEmbeddedBaseComponent } from 'core-app/features/work-packages/components/wp-table/embedded/wp-embedded-base.component';

function fromPrototype<T extends object>(prototype:T, properties:Record<string, unknown>):T {
  return Object.assign(Object.create(prototype) as T, properties);
}

function queryWithResults(name:string):QueryResource {
  return { name, results: { name } } as unknown as QueryResource;
}

async function settled():Promise<void> {
  await new Promise((resolve) => { setTimeout(resolve); });
}

describe('table reloads', () => {
  let responses:Subject<QueryResource>[];
  const loadQueryFromExisting = () => {
    const response = new Subject<QueryResource>();
    responses.push(response);
    return response;
  };
  const respond = (index:number, query:QueryResource) => {
    responses[index].next(query);
    responses[index].complete();
  };

  beforeEach(() => {
    responses = [];
  });

  describe('of the work packages page', () => {
    it('cancel the superseded reload and apply only the latest response', async () => {
      const initialize = vi.fn();
      const page = fromPrototype(PartitionedQuerySpacePageComponent.prototype, {
        reloads: new LatestOnly(),
        currentQuery: queryWithResults('current'),
        currentProject: { identifier: null },
        wpListService: { getPaginationInfo: () => ({}), loadQueryFromExisting },
        wpStatesInitialization: { initialize },
      });
      const older = queryWithResults('older');
      const newer = queryWithResults('newer');

      page.refresh(false, false);
      page.refresh(false, false);
      expect(responses[0].observed).toBe(false);
      respond(1, newer);
      respond(0, older);
      await settled();

      expect(initialize).toHaveBeenCalledTimes(1);
      expect(initialize).toHaveBeenCalledWith(newer, newer.results);
    });

    it('are cancelled when the page is destroyed', () => {
      const page = fromPrototype(PartitionedQuerySpacePageComponent.prototype, {
        reloads: new LatestOnly(),
        currentQuery: queryWithResults('current'),
        currentProject: { identifier: null },
        wpListService: { getPaginationInfo: () => ({}), loadQueryFromExisting },
        wpStatesInitialization: { initialize: vi.fn() },
        queryParamListener: { removeQueryChangeListener: () => undefined },
        observeOnDestroy: () => new Subject<void>(),
      });
      page.refresh(false, false);
      expect(responses[0].observed).toBe(true);

      page.ngOnDestroy();

      expect(responses[0].observed).toBe(false);
    });
  });

  describe('of the BIM viewer page', () => {
    it('initialize the BCF view with the latest response only', async () => {
      const initializeBcfView = vi.fn();
      const page = fromPrototype(IFCViewerPageComponent.prototype, {
        reloads: new LatestOnly(),
        currentQuery: queryWithResults('current'),
        currentProject: { identifier: null },
        wpListService: { getPaginationInfo: () => ({}), loadQueryFromExisting },
        wpStatesInitialization: { initialize: vi.fn() },
        bcfView: { initialize: initializeBcfView },
      });
      const older = queryWithResults('older');
      const newer = queryWithResults('newer');

      page.refresh(false, false);
      page.refresh(false, false);
      respond(1, newer);
      respond(0, older);
      await settled();

      expect(initializeBcfView).toHaveBeenCalledExactlyOnceWith(newer, newer.results);
    });
  });

  describe('of an embedded table', () => {
    it('cancel the superseded reload and apply only the latest response', async () => {
      const updateQuerySpace = vi.fn();
      const embedded = fromPrototype(WorkPackageEmbeddedBaseComponent.prototype, {
        reloads: new LatestOnly(),
        querySpace: { query: { value: queryWithResults('current') } },
        configuration: { projectContext: false, tableVisible: false },
        wpTablePagination: { paginationObject: {} },
        urlParamsHelper: { buildV3GetQueryFromQueryResource: () => ({}) },
        wpListService: { loadQueryFromExisting },
        wpStatesInitialization: { updateQuerySpace },
      });
      const older = queryWithResults('older');
      const newer = queryWithResults('newer');

      embedded.refresh(false, false);
      embedded.refresh(false, false);
      expect(responses[0].observed).toBe(false);
      respond(1, newer);
      respond(0, older);
      await settled();

      expect(updateQuerySpace).toHaveBeenCalledTimes(1);
      expect(updateQuerySpace).toHaveBeenCalledWith(newer, newer.results);
    });
  });
});
