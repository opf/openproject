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

import { createEnvironmentInjector, EnvironmentInjector, Injector, Provider } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpClient } from '@angular/common/http';
import { waitFor } from '@testing-library/dom';
import { of, Subject } from 'rxjs';
import * as Turbo from '@hotwired/turbo';
import { nextTask } from 'core-common/testing/timing';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { States } from 'core-app/core/states/states.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WorkPackageCache } from 'core-app/core/apiv3/endpoints/work_packages/work-package.cache';
import { SubmenuService } from 'core-app/core/main-menu/submenu.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { HalResourceEditingService, ResourceChangesetCommit } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { HookService } from 'core-app/features/plugins/hook-service';
import { WorkPackagesActivityService } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { WorkPackageViewPaginationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { WorkPackagesQueryViewService } from 'core-app/features/work-packages/components/wp-list/wp-query-view.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { WorkPackagesListInvalidQueryService } from 'core-app/features/work-packages/components/wp-list/wp-list-invalid-query.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { buildDom, buildQuery, buildTable, TableHarness } from '../../testing/table-harness';

function deferred<T>() {
  let resolve!:(value:T) => void;
  let reject!:(error:unknown) => void;
  const promise = new Promise<T>((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

const manualSort = { column: { href: '/api/v3/queries/columns/manualSorting' }, direction: { href: '/asc' } } as QuerySortByResource;

function query(saved = true, grouped = false, hierarchy = false):QueryResource {
  return Object.assign(buildQuery(['id', 'subject'], grouped ? 'status' : null, hierarchy, false), {
    id: saved ? '10' : null,
    href: saved ? '/api/v3/queries/10' : null,
    public: true,
    user: { id: '1' },
    project: { href: '/api/v3/projects/9' },
    $links: { update: { href: '/api/v3/queries/10/form' } },
    orderedWorkPackages: {},
    setSortBy(this:QueryResource, sort:QuerySortByResource[]) { this.sortBy = sort; },
  });
}

const form = { href: '/api/v3/queries/10/form' } as QueryFormResource;
const status1 = { href: '/api/v3/statuses/1' };
const status2 = { href: '/api/v3/statuses/2' };

describe('accepted table drag persistence lifetime', () => {
  let table:TableHarness;
  let successor:TableHarness|undefined;
  let calls:string[];
  let completions:boolean[];
  let states:States;
  let original:QueryResource;
  let orderSaved:ReturnType<typeof deferred<string>>;
  let actionSaved:ReturnType<typeof deferred<WorkPackageResource>>;
  let querySaved:Subject<QueryResource>;
  let formLoaded:Subject<[QueryFormResource, QueryResource]>;
  let positionsLoaded:ReturnType<typeof deferred<Record<string, number>>>;
  let resourceLoaded:Subject<WorkPackageResource>;
  let delayResource:boolean;
  let delayPositions:boolean;
  let delayForm:boolean;
  let delayParent:boolean;
  let parentLoaded:Subject<WorkPackageResource>;
  let dom:ReturnType<typeof buildDom>;
  let workPackage:WorkPackageResource;
  let savedWorkPackage:WorkPackageResource;
  let resourceInjector:EnvironmentInjector|undefined;
  let editing:HalResourceEditingService;
  let commits:ResourceChangesetCommit[];
  const notify = { handleRawError: vi.fn(), showSave: vi.fn() };
  const toast = { addSuccess: vi.fn(), addError: vi.fn() };
  const menu = { reloadSubmenu: vi.fn() };
  const patch = vi.fn();
  const post = vi.fn();
  const view = vi.fn();
  const orderWrite = vi.fn();
  const saveGroup = vi.fn();
  const loadGroupForm = vi.fn();
  const changeParent = vi.fn();

  async function expectCalls(expected:string[]) {
    await waitFor(() => expect(calls).toEqual(expected));
  }

  async function mount(kind:'default'|'group'|'hierarchy' = 'group', saved = true) {
    const grouped = kind === 'group';
    original = query(saved, grouped, kind === 'hierarchy');
    const providers:Provider[] = [
      WorkPackagesListService,
      WorkPackagesQueryViewService,
      WorkPackageRelationsHierarchyService,
      WorkPackageViewPaginationService,
      PaginationService,
      HalResourceEditingService,
      HalEventsService,
      HookService,
      { provide: UrlParamsHelperService, useValue: {} },
      { provide: AuthorisationService, useValue: {} },
      { provide: ConfigurationService, useValue: { perPageOptions: [20, 50] } },
      { provide: CurrentUserService, useValue: { userId: '1' } },
      { provide: WorkPackageStatesInitializationService, useValue: {} },
      { provide: WorkPackagesListInvalidQueryService, useValue: {} },
      { provide: SubmenuService, useValue: menu },
      { provide: ToastService, useValue: toast },
      { provide: HalResourceNotificationService, useValue: notify },
      { provide: SchemaCacheService, useValue: {
        of: () => ({ isAttributeEditable: () => true, ofProperty: () => undefined, mappedName: (name:string) => name }),
        state: () => ({ value: undefined }),
      } },
      { provide: ApiV3Service, useValue: {
        work_packages: {
          requireAll: (ids:string[]) => Promise.resolve(ids.map((id) => states.workPackages.get(id).value!)),
          cache: { current: (_id:string, fallback:unknown) => fallback, state: (id:string) => states.workPackages.get(id), updateWorkPackage: vi.fn() },
          id: (id:string) => ({
            path: `/api/v3/work_packages/${id}`,
            get: () => {
              if (delayParent && id === '2') { calls.push('parent'); return parentLoaded; }
              return delayResource ? resourceLoaded : of(states.workPackages.get(id).value!);
            },
          }),
        },
        queries: {
          id: () => ({ order: { get: () => delayPositions ? positionsLoaded.promise : Promise.resolve({ '1': 10, '2': 20, '3': 30 }), update: orderWrite }, patch }),
          post,
          form: { load: () => { calls.push('form'); return delayForm ? formLoaded : of([form, original]); } },
        },
        views: { post: view },
      } },
    ];
    dom = buildDom();
    table = buildTable({
      query: original,
      builtinDragActions: true,
      states,
      providers,
      dom,
      onDropComplete: (success) => completions.push(success),
      workPackages: [
        { id: '1', attributes: { status: status1, changeParent } },
        { id: '2', attributes: { status: status2, parent: { id: '3' } }, ...(kind === 'hierarchy' ? { ancestors: [{ id: '3' }] } : {}) },
        { id: '3', attributes: { status: status2 } },
        ...(kind === 'hierarchy' ? [{ id: '4', ancestors: [{ id: '3' }] }] : []),
      ],
      groups: grouped ? [{ value: 'New', href: status1.href, count: 1 }, { value: 'Progress', href: status2.href, count: 2 }] : undefined,
      showHierarchies: kind === 'hierarchy',
    });
    await table.render();
    table.injector.get(WorkPackageViewPaginationService).initialize(original, { elements: [], offset: 1, pageSize: 50, total: 3, count: 3 } as unknown as WorkPackageCollectionResource);
    table.querySpace.queryForm.putValue(form);
    table.querySpace.available.sortBy.putValue([manualSort]);
    workPackage = states.workPackages.get('1').value!;
    editing = table.injector.get(HalResourceEditingService);
    editing.committedChanges.subscribe((commit) => commits.push(commit));
    if (grouped) {
      resourceInjector = createEnvironmentInjector([
        { provide: States, useValue: states },
        { provide: HttpClient, useValue: {} },
        { provide: ConfigurationService, useValue: {} },
        { provide: TimezoneService, useValue: {} },
        HalResourceService,
        SchemaCacheService,
        WorkPackagesActivityService,
        { provide: ApiV3Service, useFactory: (injector:Injector) => ({ work_packages: { cache: new WorkPackageCache(injector, states.workPackages) } }), deps: [Injector] },
      ], TestBed.inject(EnvironmentInjector));
      const factory = resourceInjector.get(HalResourceService);
      factory.registerResource('WorkPackage', { cls: WorkPackageResource });
      factory.registerResource('Schema', { cls: SchemaResource });
      const schema = factory.createHalResourceOfClass(SchemaResource, {
        _type: 'Schema',
        _links: { self: { href: '/api/v3/work_packages/schemas/9-1' } },
        status: { type: 'Status', writable: true },
      }, true);
      states.schemas.get(schema.href).putValue(schema);
      const source = {
        id: '1', subject: 'Work package 1', _type: 'WorkPackage', lockVersion: 1,
        _links: {
          self: { href: '/api/v3/work_packages/1' },
          schema: { href: schema.href },
          status: status1,
          update: { href: '/api/v3/work_packages/1/form', method: 'post' },
          updateImmediately: { href: '/api/v3/work_packages/1', method: 'patch' },
        },
      };
      workPackage = factory.createHalResourceOfClass(WorkPackageResource, source, true);
      savedWorkPackage = factory.createHalResourceOfClass(WorkPackageResource, {
        ...source, lockVersion: 2, _links: { ...source._links, status: status2 },
      }, true);
      const workPackageForm = factory.createHalResourceOfClass(FormResource, {
        _type: 'Form',
        _embedded: { schema: schema.$source, payload: source },
      }, true);
      loadGroupForm.mockResolvedValue(workPackageForm);
      workPackage.$links = { ...workPackage.$links, update: loadGroupForm, updateImmediately: saveGroup };
      states.workPackages.get('1').putValue(workPackage);
    }
  }

  async function retire() {
    await table.destroy();
    document.body.appendChild(dom.wrapper);
    successor = buildTable({ dom, states, workPackages: [{ id: '3' }, { id: '2' }, { id: '1' }] });
    await successor.render();
    if (resourceInjector) states.workPackages.get('1').putValue(workPackage);
    const successorQuery = successor.querySpace.query.value;
    const successorState = successor.renderedState();
    const successorDom = successor.container.innerHTML;
    return () => {
      expect(successor!.querySpace.query.value).toBe(successorQuery);
      expect(successor!.renderedState()).toEqual(successorState);
      expect(successor!.container.innerHTML).toBe(successorDom);
    };
  }

  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubGlobal('OpenProject', { guardedLocalStorage: () => undefined });
    window.history.replaceState({}, '', '/projects/demo/work_packages');
    vi.spyOn(Turbo.session.history, 'push').mockImplementation(() => undefined);
    calls = [];
    completions = [];
    states = new States();
    orderSaved = deferred<string>();
    actionSaved = deferred<WorkPackageResource>();
    querySaved = new Subject<QueryResource>();
    formLoaded = new Subject<[QueryFormResource, QueryResource]>();
    positionsLoaded = deferred<Record<string, number>>();
    resourceLoaded = new Subject<WorkPackageResource>();
    delayResource = false;
    delayPositions = false;
    delayForm = false;
    delayParent = false;
    parentLoaded = new Subject<WorkPackageResource>();
    commits = [];
    orderWrite.mockImplementation(() => { calls.push('order'); return orderSaved.promise; });
    saveGroup.mockImplementation(() => { calls.push('action'); return actionSaved.promise; });
    changeParent.mockImplementation(() => { calls.push('action'); return actionSaved.promise; });
    patch.mockImplementation(() => { calls.push('query'); return querySaved; });
    post.mockImplementation(() => { calls.push('query'); return querySaved; });
    view.mockReturnValue(of({}));
  });

  afterEach(async () => {
    await table?.destroy();
    await successor?.destroy();
    successor = undefined;
    resourceInjector?.destroy();
    resourceInjector = undefined;
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it.each(['default', 'group', 'hierarchy'] as const)('finishes the accepted %s drop after order disposal', async (kind) => {
    await mount(kind);
    expect(editing).toBeInstanceOf(HalResourceEditingService);
    const dropping = table.drop('1', kind === 'hierarchy' ? '3' : '2', 'bottom');
    await expectCalls(['order']);
    expect(editing.typedState(workPackage).value).toBeUndefined();
    const checkSuccessor = await retire();
    orderSaved.resolve('now');
    await expectCalls(kind === 'default' ? ['order', 'query'] : ['order', 'action']);
    const change = editing.typedState(workPackage).value;
    const changesetType = expect.any(ResourceChangeset);
    expect(change).toEqual(kind === 'group' ? changesetType : undefined);
    expect(change?.changes).toEqual(kind === 'group' ? { status: status2 } : undefined);
    const payload = { lockVersion: 1, _links: { status: status2 } };
    expect(loadGroupForm.mock.calls).toEqual(kind === 'group' ? [[payload]] : []);
    expect(saveGroup.mock.calls).toEqual(kind === 'group' ? [[payload]] : []);
    expect(changeParent.mock.calls).toEqual(kind === 'hierarchy'
      ? [[{ lockVersion: undefined, _links: { parent: { href: '/api/v3/work_packages/3' } } }]]
      : []);
    if (kind !== 'default') actionSaved.resolve(kind === 'group' ? savedWorkPackage : workPackage);
    await expectCalls(kind === 'default' ? ['order', 'query'] : ['order', 'action', 'query']);
    expect(patch).toHaveBeenCalledWith(original, form);
    querySaved.next(original);
    expect(await dropping).toBe(true);
    expect(completions).toEqual([true]);
    expect(original.sortBy).toEqual([manualSort]);
    expect(notify.handleRawError).not.toHaveBeenCalled();
    expect(menu.reloadSubmenu).not.toHaveBeenCalled();
    expect(commits.map((commit) => commit.resource)).toEqual(kind === 'group' ? [savedWorkPackage] : []);
    expect(commits[0]?.changes).toEqual(kind === 'group' ? { status: { from: workPackage.status, to: status2 } } : undefined);
    expect(commits[0]?.resource.state?.value).toBe(kind === 'group' ? savedWorkPackage : undefined);
    expect(commits[0]?.resource.status.href).toBe(kind === 'group' ? status2.href : undefined);
    expect(commits[0]?.resource.lockVersion).toBe(kind === 'group' ? 2 : undefined);
    expect(editing.typedState(workPackage).value).toBeUndefined();
    expect(change?.isEmpty()).toBe(kind === 'group' ? true : undefined);
    checkSuccessor();
  });

  it.each(['order', 'action', 'query'] as const)('reports one resource-aware %s failure after acceptance', async (phase) => {
    await mount();
    const error = new Error(`${phase} failed`);
    const dropping = table.drop('1', '2', 'bottom');
    await expectCalls(['order']);
    const checkSuccessor = await retire();
    if (phase === 'order') orderSaved.reject(error);
    else {
      orderSaved.resolve('now');
      await expectCalls(['order', 'action']);
      if (phase === 'action') actionSaved.reject(error);
      else {
        actionSaved.resolve(savedWorkPackage);
        await expectCalls(['order', 'action', 'query']);
        querySaved.error(error);
      }
    }
    expect(await dropping).toBe(false);
    expect(completions).toEqual([false]);
    expect(calls).toEqual(['order', 'action', 'query'].slice(0, ['order', 'action', 'query'].indexOf(phase) + 1));
    expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage);
    expect(toast.addError).not.toHaveBeenCalled();
    expect(commits).toHaveLength(phase === 'query' ? 1 : 0);
    expect(states.workPackages.get('1').value).toBe(phase === 'query' ? savedWorkPackage : workPackage);
    const change = editing.typedState(workPackage).value;
    const changesetType = expect.any(ResourceChangeset);
    expect(change).toEqual(phase === 'action' ? changesetType : undefined);
    expect(change?.changes).toEqual(phase === 'action' ? { status: status2 } : undefined);
    checkSuccessor();
  });

  it.each(['default', 'group'] as const)('keeps the saved %s order visible when query saving fails', async (kind) => {
    await mount(kind);
    const refresh = vi.spyOn(table.table, 'initialSetup');
    const dropping = table.drop('1', '2', 'bottom');
    await expectCalls(['order']);
    orderSaved.resolve('now');
    if (kind === 'group') {
      await expectCalls(['order', 'action']);
      actionSaved.resolve(savedWorkPackage);
    }
    await expectCalls(kind === 'group' ? ['order', 'action', 'query'] : ['order', 'query']);
    const error = new Error('query failed');
    querySaved.error(error);
    expect(await dropping).toBe(false);
    await waitFor(() => expect(table.renderedState()).toEqual([['2', false], ['1', false], ['3', false]]));
    expect(table.rowIds()).toEqual(['2', '1', '3']);
    expect(refresh).toHaveBeenCalledExactlyOnceWith([
      states.workPackages.get('2').value!,
      kind === 'group' ? savedWorkPackage : workPackage,
      states.workPackages.get('3').value!,
    ]);
    expect(orderWrite).toHaveBeenCalledTimes(1);
    expect(saveGroup).toHaveBeenCalledTimes(kind === 'group' ? 1 : 0);
    expect(patch).toHaveBeenCalledExactlyOnceWith(original, form);
    expect(completions).toEqual([false]);
    expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage);
    expect(original.sortBy).toEqual([manualSort]);
    expect(commits.map((commit) => commit.resource)).toEqual(kind === 'group' ? [savedWorkPackage] : []);
  });

  it.each(['order', 'action'] as const)('restores the live row after a %s save failure', async (phase) => {
    await mount();
    const refresh = vi.spyOn(table.table, 'initialSetup');
    const dropping = table.drop('1', '2', 'bottom');
    await expectCalls(['order']);
    expect(table.rowIds()).toEqual(['2', '1', '3']);
    const error = new Error(`${phase} failed`);
    if (phase === 'order') orderSaved.reject(error);
    else {
      orderSaved.resolve('now');
      await expectCalls(['order', 'action']);
      actionSaved.reject(error);
    }
    expect(await dropping).toBe(false);
    expect(table.rowIds()).toEqual(['1', '2', '3']);
    expect(refresh).not.toHaveBeenCalled();
    expect(patch).not.toHaveBeenCalled();
    expect(completions).toEqual([false]);
    expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage);
  });

  it.each(['retirement', 'query replacement'] as const)('skips query-failure UI work after %s during query saving', async (change) => {
    await mount();
    const refresh = vi.spyOn(table.table, 'initialSetup');
    const dropping = table.drop('1', '2', 'bottom');
    await expectCalls(['order']);
    orderSaved.resolve('now');
    await expectCalls(['order', 'action']);
    actionSaved.resolve(savedWorkPackage);
    await expectCalls(['order', 'action', 'query']);
    const checkSuccessor = change === 'retirement' ? await retire() : () => undefined;
    if (change === 'query replacement') table.querySpace.query.putValue(query());
    const activeQuery = table.querySpace.query.value;
    const rendered = table.renderedState();
    const html = table.container.innerHTML;
    const error = new Error('query failed');
    querySaved.error(error);
    expect(await dropping).toBe(false);
    await nextTask();
    expect(refresh).not.toHaveBeenCalled();
    expect(orderWrite).toHaveBeenCalledTimes(1);
    expect(saveGroup).toHaveBeenCalledTimes(1);
    expect(patch).toHaveBeenCalledExactlyOnceWith(original, form);
    expect(completions).toEqual([false]);
    expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage);
    expect(commits.map((commit) => commit.resource)).toEqual([savedWorkPackage]);
    expect(table.querySpace.query.value).toBe(activeQuery);
    expect(table.renderedState()).toEqual(rendered);
    expect(table.container.innerHTML).toBe(html);
    checkSuccessor();
  });

  it('lets the adapter report a hierarchy failure once with the captured resource', async () => {
    await mount('hierarchy');
    const dropping = table.drop('1', '3', 'bottom');
    await expectCalls(['order']);
    await table.destroy();
    orderSaved.resolve('now');
    await expectCalls(['order', 'action']);
    const error = new Error('parent failed');
    actionSaved.reject(error);
    expect(await dropping).toBe(false);
    expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage);
    expect(patch).not.toHaveBeenCalled();
  });

  it.each(['resource', 'positions', 'form'] as const)('cancels silently during %s preparation before any write', async (phase) => {
    await mount();
    if (phase === 'resource') delayResource = true;
    if (phase === 'positions') delayPositions = true;
    if (phase === 'form') { delayForm = true; table.querySpace.queryForm.clear(); }
    const dropping = table.drop('1', '2', 'bottom');
    if (phase === 'resource') await nextTask();
    if (phase === 'positions') await nextTask();
    if (phase === 'form') await expectCalls(['form']);
    const checkSuccessor = await retire();
    resourceLoaded.next(workPackage);
    positionsLoaded.resolve({ '1': 10, '2': 20, '3': 30 });
    formLoaded.next([form, original]);
    expect(await dropping).toBe(false);
    expect(completions).toEqual([false]);
    expect(orderWrite).not.toHaveBeenCalled();
    expect(saveGroup).not.toHaveBeenCalled();
    expect(patch).not.toHaveBeenCalled();
    expect(notify.handleRawError).not.toHaveBeenCalled();
    checkSuccessor();
  });

  it('cancels during hierarchy parent preparation without touching the successor root', async () => {
    await mount('hierarchy');
    delayParent = true;
    const dropping = table.drop('1', '2', 'bottom');
    await expectCalls(['parent']);
    const checkSuccessor = await retire();
    parentLoaded.next(states.workPackages.get('2').value!);
    parentLoaded.complete();
    expect(await dropping).toBe(false);
    expect(orderWrite).not.toHaveBeenCalled();
    expect(changeParent).not.toHaveBeenCalled();
    expect(notify.handleRawError).not.toHaveBeenCalled();
    checkSuccessor();
  });

  it.each(['positions', 'form', 'parent'] as const)('reports genuine %s preparation failures after disposal', async (phase) => {
    await mount(phase === 'parent' ? 'hierarchy' : 'group');
    delayPositions = phase === 'positions';
    delayParent = phase === 'parent';
    if (phase === 'form') { delayForm = true; table.querySpace.queryForm.clear(); }
    const dropping = table.drop('1', '2', 'bottom');
    if (phase === 'positions') await nextTask();
    else await expectCalls([phase]);
    const checkSuccessor = await retire();
    const error = new Error(`${phase} failed`);
    if (phase === 'positions') positionsLoaded.reject(error);
    if (phase === 'form') formLoaded.error(error);
    if (phase === 'parent') parentLoaded.error(error);
    expect(await dropping).toBe(false);
    expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage);
    expect(orderWrite).not.toHaveBeenCalled();
    checkSuccessor();
  });

  it('observes a failed shared resource request after disposal', async () => {
    await mount();
    delayResource = true;
    const dropping = table.drop('1', '2', 'bottom');
    await table.destroy();
    const error = new Error('shared request failed');
    resourceLoaded.error(error);
    expect(await dropping).toBe(false);
    expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage);
    expect(orderWrite).not.toHaveBeenCalled();
  });

  it.each(['render', 'query', 'order', 'permission', 'target'] as const)('revalidates %s after preparation and makes no writes', async (change) => {
    await mount();
    delayForm = true;
    table.querySpace.queryForm.clear();
    const dropping = table.drop('1', '2', 'bottom');
    await expectCalls(['form']);
    if (change === 'render') await table.render();
    if (change === 'query') table.querySpace.query.putValue(query());
    if (change === 'order') table.querySpace.tableRendered.putValue([]);
    if (change === 'permission') vi.spyOn(table.injector.get(SchemaCacheService), 'of').mockReturnValue({ isAttributeEditable: () => false } as unknown as ReturnType<SchemaCacheService['of']>);
    if (change === 'target') table.row('2').remove();
    const dom = table.container.innerHTML;
    formLoaded.next([form, original]);
    expect(await dropping).toBe(false);
    expect(orderWrite).not.toHaveBeenCalled();
    expect(notify.handleRawError).not.toHaveBeenCalled();
    const checkDom = () => expect(table.container.innerHTML).toBe(dom);
    if (change === 'render' || change === 'query') checkDom();
  });

  it('rejects a vanished target rather than treating it as a valid no-op', async () => {
    await mount();
    expect(await table.drop('1', 'missing', 'top')).toBe(false);
    expect(orderWrite).not.toHaveBeenCalled();
    expect(completions).toEqual([false]);
  });

  it.each(['group', 'hierarchy'] as const)('finishes a pending %s save after disposal', async (kind) => {
    await mount(kind);
    const dropping = table.drop('1', kind === 'hierarchy' ? '3' : '2', 'bottom');
    await expectCalls(['order']);
    orderSaved.resolve('now');
    await expectCalls(['order', 'action']);
    const checkSuccessor = await retire();
    actionSaved.resolve(kind === 'group' ? savedWorkPackage : workPackage);
    await expectCalls(['order', 'action', 'query']);
    querySaved.next(original);
    expect(await dropping).toBe(true);
    expect(completions).toEqual([true]);
    expect(notify.handleRawError).not.toHaveBeenCalled();
    expect(commits.map((commit) => commit.resource)).toEqual(kind === 'group' ? [savedWorkPackage] : []);
    expect(commits[0]?.resource.state?.value).toBe(kind === 'group' ? savedWorkPackage : undefined);
    expect(editing.typedState(workPackage).value).toBeUndefined();
    checkSuccessor();
  });

  it('reports a pending real group save rejection after table and injector disposal', async () => {
    await mount();
    const dropping = table.drop('1', '2', 'bottom');
    await expectCalls(['order']);
    orderSaved.resolve('now');
    await expectCalls(['order', 'action']);
    const change = editing.typedState(workPackage).value;
    expect(change).toBeInstanceOf(ResourceChangeset);
    const payload = { lockVersion: 1, _links: { status: status2 } };
    expect(loadGroupForm).toHaveBeenCalledExactlyOnceWith(payload);
    expect(saveGroup).toHaveBeenCalledExactlyOnceWith(payload);
    const checkSuccessor = await retire();
    const error = new Error('group save failed');
    actionSaved.reject(error);
    expect(await dropping).toBe(false);
    expect(completions).toEqual([false]);
    expect(calls).toEqual(['order', 'action']);
    expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage);
    expect(patch).not.toHaveBeenCalled();
    expect(commits).toEqual([]);
    expect(states.workPackages.get('1').value).toBe(workPackage);
    expect(editing.typedState(workPackage).value).toBe(change);
    expect(change?.changes).toEqual({ status: status2 });
    checkSuccessor();
  });

  it.each([true, false])('finishes a pending query save after disposal (saved=%s)', async (saved) => {
    await mount('default', saved);
    const dropping = table.drop('1', '2', 'bottom');
    if (saved) {
      await expectCalls(['order']);
      orderSaved.resolve('now');
    }
    await waitFor(() => expect(calls).toContain('query'));
    const checkSuccessor = await retire();
    querySaved.next(query(true));
    expect(await dropping).toBe(true);
    expect(saved ? patch : post).toHaveBeenCalledWith(original, form);
    expect(view).toHaveBeenCalledTimes(saved ? 0 : 1);
    expect(completions).toEqual([true]);
    checkSuccessor();
  });

  it.each(['query', 'view'] as const)('reports an unsaved %s failure after disposal once', async (phase) => {
    await mount('default', false);
    const viewSaved = new Subject<object>();
    view.mockReturnValue(viewSaved);
    const dropping = table.drop('1', '2', 'bottom');
    await expectCalls(['query']);
    const checkSuccessor = await retire();
    const error = new Error(`${phase} failed`);
    if (phase === 'query') querySaved.error(error);
    else {
      querySaved.next(query(true));
      viewSaved.error(error);
    }
    expect(await dropping).toBe(false);
    expect(completions).toEqual([false]);
    expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage);
    expect(toast.addError).not.toHaveBeenCalled();
    checkSuccessor();
  });

  it('completes persistence before refresh and reports refresh errors without failing the drop', async () => {
    await mount('default');
    const dropping = table.drop('1', '2', 'bottom');
    await expectCalls(['order']);
    orderSaved.resolve('now');
    await expectCalls(['order', 'query']);
    delayResource = true;
    querySaved.next(original);
    expect(await dropping).toBe(true);
    const error = new Error('refresh failed');
    resourceLoaded.error(error);
    await waitFor(() => expect(notify.handleRawError).toHaveBeenCalledExactlyOnceWith(error, workPackage));
    expect(completions).toEqual([true]);
  });

  it.each([false, true])('owns inline-create preparation and accepted saving (accepted=%s)', async (accepted) => {
    await mount('default');
    delayPositions = !accepted;
    const inline = table.injector.get(WorkPackageInlineCreateService);
    inline.newInlineWorkPackageCreated.next('4');
    if (accepted) await expectCalls(['order']);
    else await nextTask();
    const checkSuccessor = await retire();
    positionsLoaded.resolve({});
    orderSaved.resolve('now');
    await nextTask();
    await nextTask();
    expect(orderWrite).toHaveBeenCalledTimes(accepted ? 1 : 0);
    expect(saveGroup).not.toHaveBeenCalled();
    expect(patch).not.toHaveBeenCalled();
    expect(notify.handleRawError).not.toHaveBeenCalled();
    checkSuccessor();
  });
});
