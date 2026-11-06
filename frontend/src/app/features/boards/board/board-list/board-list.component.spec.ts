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

import { ChangeDetectorRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom, NEVER, of, Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { States } from 'core-app/core/states/states.service';
import { Board } from 'core-app/features/boards/board/board';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { BoardFiltersService } from 'core-app/features/boards/board/board-filter/board-filters.service';
import { BoardListCrossSelectionService } from 'core-app/features/boards/board/board-list/board-list-cross-selection.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalEvent, HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageCardDragAndDropService } from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-drag-and-drop.service';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { ChangeItem } from 'core-app/shared/components/fields/changeset/changeset';
import { HalResourceEditingService, ResourceChangesetCommit } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { BoardStatusActionService } from '../board-actions/status/status-action.service';
import { BoardSubprojectActionService } from '../board-actions/subproject/subproject-action.service';
import { BoardListComponent, listNeedsReload } from './board-list.component';
import { BoardListsService } from './board-lists.service';

describe('listNeedsReload', () => {
  const newStatus = '/api/v3/statuses/1';
  const inProgress = '/api/v3/statuses/7';
  const toInProgress:ChangeItem = { from: { href: newStatus }, to: { href: inProgress } };
  const cards = (...ids:string[]) => ids.map((id) => ({ id }));

  it('is false when the card was already moved into the target list', () => {
    expect(listNeedsReload(inProgress, cards('1', '42'), '42', toInProgress)).toBe(false);
  });

  it('is false when the card was already removed from the source list', () => {
    expect(listNeedsReload(newStatus, cards('1'), '42', toInProgress)).toBe(false);
  });

  it('is true when the target list does not show the card yet', () => {
    expect(listNeedsReload(inProgress, cards('1'), '42', toInProgress)).toBe(true);
  });

  it('is true when the source list still shows the card', () => {
    expect(listNeedsReload(newStatus, cards('1', '42'), '42', toInProgress)).toBe(true);
  });

  it('is false for a list the change does not touch', () => {
    expect(listNeedsReload('/api/v3/statuses/3', cards('1'), '42', toInProgress)).toBe(false);
  });

  it('is false without an action resource', () => {
    expect(listNeedsReload(undefined, cards('1'), '42', toInProgress)).toBe(false);
  });

  it('handles multi value attributes', () => {
    const versions:ChangeItem = { from: [], to: [{ href: '/api/v3/versions/1' }, { href: '/api/v3/versions/2' }] };

    expect(listNeedsReload('/api/v3/versions/2', cards('42'), '42', versions)).toBe(false);
    expect(listNeedsReload('/api/v3/versions/2', cards(), '42', versions)).toBe(true);
  });
});

describe('board list reconciliation after work package saves', () => {
  const from = { href: '/api/v3/statuses/1', isClosed: false };
  const to = { href: '/api/v3/statuses/2', isClosed: false };
  const closed = { href: '/api/v3/statuses/3', isClosed: true };

  async function list(action:string, listValue = from) {
    const events = new Subject<HalEvent>();
    const filters:ApiV3Filter[] = [];
    const results = { count: 2, total: 2, pageSize: 500 };
    const cards = [{ id: 'card', ancestorIds: [] as string[] }];
    const registry = { get: vi.fn() };
    TestBed.configureTestingModule({ providers: [
      BoardStatusActionService,
      BoardSubprojectActionService,
      { provide: HalEventsService, useValue: { events$: events } },
      { provide: IsolatedQuerySpace, useValue: { results: { value: results }, query: { values$: () => NEVER } } },
      { provide: WorkPackageCardDragAndDropService, useValue: { workPackages: cards } },
      { provide: BoardFiltersService, useValue: { filters: { values$: () => NEVER }, current: filters } },
      { provide: WorkPackageViewSelectionService, useValue: { updates$: () => NEVER } },
      { provide: BoardListCrossSelectionService, useValue: { selectionsForQuery: () => NEVER } },
      { provide: WorkPackageInlineCreateService, useValue: { canAdd: of(true) } },
      { provide: States, useValue: { workPackages: { get: () => ({}) } } },
      { provide: HalResourceEditingService, useValue: { changeFor: () => ({ isEmpty: () => true }) } },
      { provide: ApiV3Service, useValue: {
        statuses: { get: () => of({ elements: [from, to, closed] }) },
        queries: { find: () => NEVER },
        work_packages: { cache: { updateWorkPackage: vi.fn() } },
      } },
      { provide: I18nService, useValue: { t: (key:string) => key } },
      { provide: BoardActionsRegistryService, useValue: registry },
      ...[
        ChangeDetectorRef,
        ToastService,
        HalResourceNotificationService,
        WorkPackageStatesInitializationService,
        WorkPackageViewFocusService,
        AuthorisationService,
        LoadingIndicatorService,
        SchemaCacheService,
        BoardService,
        CausedUpdatesService,
        KeepTabService,
        CurrentProjectService,
        PathHelperService,
        BoardListsService,
        HalResourceService,
      ].map((provide) => ({ provide, useValue: {} })),
    ] });
    const statusService = TestBed.inject(BoardStatusActionService);
    await firstValueFrom(statusService.loadAvailable(new Set(), ''));
    const actionService = action === 'status' ? statusService : TestBed.inject(BoardSubprojectActionService);
    registry.get.mockReturnValue(actionService);
    const component = TestBed.runInInjectionContext(() => new BoardListComponent());
    component.board = { actionAttribute: action, isAction: true } as Board;
    component.resource = { options: { queryId: 1 } } as unknown as GridWidgetResource;
    component.actionResource = listValue as unknown as HalResource;
    const reload = vi.spyOn(component, 'updateQuery').mockImplementation(() => {});
    component.ngOnInit();
    function move(destination = to) {
      const attribute = action === 'status' ? 'status' : 'project';
      events.next({
        id: '42', resourceType: 'WorkPackage', eventType: 'updated',
        commit: {
          changes: { [attribute]: { from, to: destination } },
          resource: { id: '42', status: destination },
        } as unknown as ResourceChangesetCommit,
      });
    }
    return { move, reload, results, cards, filters, component, actionService };
  }

  it('skips an ordinary source reload but backfills a truncated source', async () => {
    const { move, reload, results } = await list('status');
    move();
    expect(reload).not.toHaveBeenCalled();
    Object.assign(results, { count: 500, total: 501 });
    move();
    expect(reload).toHaveBeenCalledOnce();
  });

  it('refreshes the destination if a list request starts while persisting its order', async () => {
    const { component, actionService, reload } = await list('status', to);
    vi.spyOn(actionService, 'assignToWorkPackage').mockImplementation(() => {});
    const result = await component.workPackageAddedHandler({ id: '42', status: to } as unknown as WorkPackageResource);
    expect(result.needsQueryRefresh?.()).toBe(false);

    reload.mockRestore();
    component.updateQuery(false);
    expect(result.needsQueryRefresh?.()).toBe(true);
  });

  it('retains the source version only while the saved links still include it', async () => {
    const { component } = await list('version', from);
    const wp = { $links: { targetVersions: [from, to] } } as unknown as WorkPackageResource;
    expect(component.retainsCard(wp)).toBe(true);
    expect(component.retainsCard({ $links: { targetVersions: [to] } } as unknown as WorkPackageResource)).toBe(false);
  });

  it('reconciles a filtered target even when the optimistic card is present', async () => {
    const { move, reload, cards, filters } = await list('status', to);
    cards.push({ id: '42', ancestorIds: [] });
    filters.push({ percentageDone: { operator: '=', values: ['0'] } });
    move();
    expect(reload).toHaveBeenCalledOnce();
  });

  it('reconciles other status columns when closing could also close duplicates', async () => {
    const { move, reload } = await list('status', { href: '/api/v3/statuses/4', isClosed: false });
    move();
    expect(reload).not.toHaveBeenCalled();
    move(closed);
    expect(reload).toHaveBeenCalledOnce();
  });

  it('only refreshes a third project column if a rendered card descends from the moved card', async () => {
    const { move, reload, cards } = await list('subproject', { href: '/api/v3/projects/other', isClosed: false });
    move();
    expect(reload).not.toHaveBeenCalled();
    cards[0].ancestorIds.push('42');
    move();
    expect(reload).toHaveBeenCalledOnce();
  });
});
