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

import { NEVER, Observable, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackagesViewBase } from 'core-app/features/work-packages/routing/wp-view-base/work-packages-view.base';
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
      await vi.waitFor(() => expect(initialize).toHaveBeenCalledExactlyOnceWith(newer, newer.results));
    });

    it('keep returning to the first page until a reload has been applied', async () => {
      const initialize = vi.fn();
      const reloadQuery = vi.fn(loadQueryFromExisting);
      const samePage = vi.fn(loadQueryFromExisting);
      const page = fromPrototype(PartitionedQuerySpacePageComponent.prototype, {
        reloads: new LatestOnly(),
        currentQuery: queryWithResults('current'),
        currentProject: { identifier: null },
        wpListService: { getPaginationInfo: () => ({}), loadQueryFromExisting: samePage, reloadQuery },
        wpStatesInitialization: { initialize },
      });

      page.refresh(false, true);
      page.refresh(false, false);
      expect(reloadQuery).toHaveBeenCalledTimes(2);
      expect(samePage).not.toHaveBeenCalled();

      respond(1, queryWithResults('first page'));
      await vi.waitFor(() => expect(initialize).toHaveBeenCalledTimes(1));
      page.refresh(false, false);

      expect(reloadQuery).toHaveBeenCalledTimes(2);
      expect(samePage).toHaveBeenCalledTimes(1);
    });

    it('cancel a first page load that a later reload supersedes', () => {
      const page = fromPrototype(PartitionedQuerySpacePageComponent.prototype, {
        reloads: new LatestOnly(),
        currentQuery: queryWithResults('current'),
        currentProject: { identifier: null },
        wpListService: { getPaginationInfo: () => ({}), loadQueryFromExisting, reloadQuery: loadQueryFromExisting },
        wpStatesInitialization: { initialize: vi.fn() },
      });

      page.refresh(false, true);
      expect(responses[0].observed).toBe(true);
      page.refresh(false, false);

      expect(responses[0].observed).toBe(false);
      expect(responses[1].observed).toBe(true);
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

      await vi.waitFor(() => expect(initializeBcfView).toHaveBeenCalledExactlyOnceWith(newer, newer.results));
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
      await vi.waitFor(() => expect(updateQuerySpace).toHaveBeenCalledExactlyOnceWith(newer, newer.results));
    });

    it('keep returning to the first page until a reload has been applied', async () => {
      const updateQuerySpace = vi.fn();
      const requestedOffsets:unknown[] = [];
      const embedded = fromPrototype(WorkPackageEmbeddedBaseComponent.prototype, {
        reloads: new LatestOnly(),
        querySpace: { query: { value: queryWithResults('current') } },
        configuration: { projectContext: false, tableVisible: false },
        wpTablePagination: { get paginationObject() { return { offset: 5 }; } },
        urlParamsHelper: {
          buildV3GetQueryFromQueryResource: (_query:unknown, pagination:{ offset:number }) => {
            requestedOffsets.push(pagination.offset);
            return {};
          },
        },
        wpListService: { loadQueryFromExisting },
        wpStatesInitialization: { updateQuerySpace },
      });

      embedded.refresh(false, true);
      embedded.refresh(false, false);
      expect(requestedOffsets).toEqual([1, 1]);

      respond(1, queryWithResults('first page'));
      await vi.waitFor(() => expect(updateQuerySpace).toHaveBeenCalledTimes(1));
      embedded.refresh(false, false);

      expect(requestedOffsets).toEqual([1, 1, 5]);
    });
  });
});

describe('a work packages view', () => {
  abstract class TestView extends WorkPackagesViewBase {
    indicatorPromises:Promise<unknown>[];

    element:HTMLElement|null;

    protected set loadingIndicator(promise:Promise<unknown>) {
      this.indicatorPromises.push(promise);
    }

    protected get loadingIndicatorElement():HTMLElement|null {
      return this.element;
    }

    get reloadsForTest():LatestOnly {
      return this.reloads;
    }
  }

  let querySpace:IsolatedQuerySpace;
  let halEvents:HalEventsService;
  let destroyed:Subject<void>;
  let element:HTMLElement;
  let refresh:ReturnType<typeof vi.fn>;
  let view:TestView;

  function buildView(space:IsolatedQuerySpace, indicatorElement:HTMLElement|null):TestView {
    const built = fromPrototype(TestView.prototype, {
      querySpace: space,
      halEvents,
      actions$: { ofType: () => NEVER },
      urlParams: { currentDetailsRouteParams: () => null },
      untilDestroyed: () => <T>(source:Observable<T>) => source.pipe(takeUntil(destroyed)),
      refresh,
      indicatorPromises: [],
      element: indicatorElement,
      reloads: new LatestOnly(),
    });
    (built as unknown as { setupRefreshObserver():void }).setupRefreshObserver();
    return built;
  }

  const workPackage = { id: '1', _type: 'WorkPackage' };

  beforeEach(() => {
    querySpace = new IsolatedQuerySpace();
    querySpace.results.putValue({ elements: [{ id: '1' }] } as never);
    halEvents = new HalEventsService();
    destroyed = new Subject<void>();
    element = document.body.appendChild(document.createElement('div'));
    refresh = vi.fn();
    view = buildView(querySpace, element);
  });

  afterEach(() => {
    element.remove();
    destroyed.next();
    vi.useRealTimers();
  });

  describe('receiving a change that originates from its own query space', () => {
    it('leaves the reload to whoever made the change', () => {
      vi.useFakeTimers();

      halEvents.push(workPackage, { eventType: 'association', origin: querySpace });
      vi.advanceTimersByTime(600);

      expect(refresh).not.toHaveBeenCalled();
    });
  });

  describe('asked to reload the table', () => {
    const rows = [{ workPackageId: '1', hidden: false, classIdentifier: 'row' }];
    let requests:Subject<QueryResource>[];
    let outcome:string;

    const reloadTable = () => {
      outcome = 'pending';
      const reload = querySpace.reloadTable.value!();
      reload.then(() => { outcome = 'rendered'; }, () => { outcome = 'failed'; });
      return reload;
    };
    // What a view does with the results of a reload, up to the table rendering them.
    const apply = (index:number) => {
      requests[index].next(queryWithResults(`reload ${index}`));
      requests[index].complete();
    };
    const initializeTable = () => querySpace.initialized.putValue(null);
    const render = () => querySpace.tableRendered.putValue(rows);
    const show = (index:number) => {
      apply(index);
      initializeTable();
      render();
    };
    const stillPending = async () => {
      await settled();
      expect(outcome).toBe('pending');
    };

    beforeEach(() => {
      requests = [];
      initializeTable();
      render();
      refresh.mockImplementation(() => {
        const request = new Subject<QueryResource>();
        requests.push(request);
        void view.reloadsForTest
          .apply(request, (query) => {
            querySpace.results.putValue(query.results);
            querySpace.tableRendered.clear('reloaded');
          })
          .catch(() => undefined);
      });
    });

    it('reloads without the loading indicator', () => {
      void reloadTable().catch(() => undefined);

      expect(refresh).toHaveBeenCalledExactlyOnceWith(false, false);
    });

    it('is done once its results are applied, the table is set up with them and has rendered', async () => {
      const reload = reloadTable();

      apply(0);
      await stillPending();
      initializeTable();
      await stillPending();
      render();

      await reload;
      expect(outcome).toBe('rendered');
    });

    it('is not done by a render that precedes its results', async () => {
      void reloadTable();

      querySpace.tableRendered.clear('unrelated');
      initializeTable();
      render();

      await settled();
      expect(outcome).toBe('pending');
    });

    it('is not done by a render that was queued before the table was set up with its results', async () => {
      const reload = reloadTable();
      apply(0);

      render();
      await stillPending();

      initializeTable();
      render();
      await reload;
      expect(outcome).toBe('rendered');
    });

    it('follows a newer reload that supersedes it', async () => {
      const reload = reloadTable();
      view.refresh(false, false);

      show(1);

      await reload;
      expect(outcome).toBe('rendered');
    });

    describe('when other results replaced its own before they were rendered', () => {
      const replace = () => querySpace.results.putValue(queryWithResults('from elsewhere').results);

      it('reloads again and is done with the results of that reload', async () => {
        const reload = reloadTable();
        apply(0);
        replace();
        initializeTable();
        render();

        await vi.waitFor(() => expect(refresh).toHaveBeenCalledTimes(2));
        expect(outcome).toBe('pending');

        show(1);
        await reload;
        expect(outcome).toBe('rendered');
      });

      it('fails after three attempts', async () => {
        const reload = reloadTable();

        for (const attempt of [0, 1, 2]) {
          await vi.waitFor(() => expect(requests).toHaveLength(attempt + 1));
          apply(attempt);
          replace();
          initializeTable();
          render();
        }

        await expect(reload).rejects.toBeInstanceOf(Error);
        expect(refresh).toHaveBeenCalledTimes(3);
      });
    });

    it('fails when the reload fails', async () => {
      const reload = reloadTable();

      requests[0].error(new Error('unavailable'));

      await expect(reload).rejects.toThrow('unavailable');
    });

    it('fails when the view is destroyed before the table has rendered', async () => {
      const reload = reloadTable();
      apply(0);

      destroyed.next();

      await expect(reload).rejects.toBeInstanceOf(Error);
    });
  });

  describe('during a table operation', () => {
    let button:HTMLButtonElement;

    beforeEach(() => {
      button = element.appendChild(document.createElement('button'));
    });

    it('takes no input and shows the indicator until the operation succeeds', async () => {
      let finish!:() => void;
      const operation = new Promise<void>((resolve) => { finish = resolve; });

      querySpace.tableOperation.putValue(operation);
      button.focus();
      expect(button).not.toHaveFocus();
      expect(view.indicatorPromises).toEqual([operation]);

      finish();
      await operation;
      button.focus();
      expect(button).toHaveFocus();
    });

    it('can take focus again in the same turn in which the operation settles', async () => {
      let finish!:() => void;
      const operation = new Promise<void>((resolve) => { finish = resolve; });
      querySpace.tableOperation.putValue(operation);
      const refocused = operation.then(() => {
        button.focus();
        return document.activeElement === button;
      });

      finish();

      expect(await refocused).toBe(true);
    });

    it('takes input again when the operation fails', async () => {
      let fail!:(reason:Error) => void;
      const operation = new Promise<void>((_resolve, reject) => { fail = reject; });
      querySpace.tableOperation.putValue(operation);

      fail(new Error('failed'));
      await operation.catch(() => undefined);

      button.focus();
      expect(button).toHaveFocus();
    });

    it('is not blocked by an operation in another query space', () => {
      new IsolatedQuerySpace().tableOperation.putValue(new Promise<void>(() => undefined));

      button.focus();
      expect(button).toHaveFocus();
      expect(view.indicatorPromises).toEqual([]);
    });

    it('shows the indicator without an element to block', () => {
      const otherSpace = new IsolatedQuerySpace();
      const elementless = buildView(otherSpace, null);
      const operation = Promise.resolve();

      otherSpace.tableOperation.putValue(operation);

      expect(elementless.indicatorPromises).toEqual([operation]);
    });
  });
});
