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

import { nextTask } from 'core-common/testing/timing';
import { TestBed } from '@angular/core/testing';
import * as Turbo from '@hotwired/turbo';
import { of, Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { States } from 'core-app/core/states/states.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { SubmenuService } from 'core-app/core/main-menu/submenu.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { IView } from 'core-app/core/state/views/view.model';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { buildQuery, FakeDragAndDropService, harnessProviders } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { WorkPackageViewPaginationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { WorkPackageViewAdditionalElementsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-additional-elements.service';
import { WorkPackageViewDisplayRepresentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { WorkPackageViewIncludeSubprojectsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { WorkPackagesListService } from './wp-list.service';
import { WorkPackagesQueryViewService } from './wp-query-view.service';
import { WorkPackageStatesInitializationService } from './wp-states-initialization.service';
import { WorkPackagesListChecksumService } from './wp-list-checksum.service';
import { WorkPackagesListInvalidQueryService } from './wp-list-invalid-query.service';

function query(id:string|null):QueryResource {
  return Object.assign(buildQuery(['id'], null, false, false), {
    id,
    href: id ? `/api/v3/queries/${id}` : null,
    name: 'original',
    public: true,
    user: { id: '1' },
    project: { href: '/api/v3/projects/9' },
    filters: [],
    timestamps: ['current'],
    orderedWorkPackages: {},
    $links: { update: { href: `/api/v3/queries/${id}/form` } },
    results: { elements: [], groups: [], offset: 1, pageSize: 50, count: 0, total: 0, $links: {} } as unknown as WorkPackageCollectionResource,
  });
}

function form(href:string):QueryFormResource {
  const allowedValues = { allowedValues: [] };
  return {
    href,
    schema: {
      filtersSchemas: { elements: [] },
      columns: allowedValues,
      sortBy: allowedValues,
      groupBy: allowedValues,
      displayRepresentation: allowedValues,
    },
  } as unknown as QueryFormResource;
}

describe('WorkPackagesListService captured persistence', () => {
  let service:WorkPackagesListService;
  let querySpace:IsolatedQuerySpace;
  let initialization:WorkPackageStatesInitializationService;
  let queryA:QueryResource;
  let queryB:QueryResource;
  let created:QueryResource;
  let loaded:QueryResource;
  let formA:QueryFormResource;
  let loadedForm:QueryFormResource;
  let patch:Subject<QueryResource>;
  let post:Subject<QueryResource>;
  let view:Subject<IView>;
  let reload:Subject<QueryResource>;
  let formReload:Subject<[QueryFormResource, QueryResource]>;
  let formPreparation:Subject<[QueryFormResource, QueryResource]>;
  let ownsA:boolean;
  const toast = { addSuccess: vi.fn(), addError: vi.fn() };
  const menu = { reloadSubmenu: vi.fn() };
  const endpointRequest = vi.fn();
  const patchRequest = vi.fn();
  const postRequest = vi.fn();
  const viewRequest = vi.fn();
  const reloadRequest = vi.fn();
  const findRequest = vi.fn();
  const loadForm = vi.fn();
  let navigate:ReturnType<typeof vi.spyOn>;
  let changes:unknown[];

  const isCurrent = (expectedQuery = queryA) => ownsA && querySpace.query.value === expectedQuery;
  const leave = () => { ownsA = false; querySpace.query.putValue(queryB); };

  beforeEach(async () => {
    vi.clearAllMocks();
    ownsA = true;
    vi.stubGlobal('OpenProject', { guardedLocalStorage: () => undefined });
    window.history.replaceState({}, '', '/projects/demo/work_packages');
    navigate = vi.spyOn(Turbo.session.history, 'push').mockImplementation(() => undefined);
    queryA = query('1');
    queryB = query('2');
    created = query('3');
    loaded = query('3');
    formA = form('/api/v3/queries/1/form');
    loadedForm = form('/api/v3/queries/3/form');
    patch = new Subject<QueryResource>();
    post = new Subject<QueryResource>();
    view = new Subject<IView>();
    reload = new Subject<QueryResource>();
    formReload = new Subject<[QueryFormResource, QueryResource]>();
    formPreparation = new Subject<[QueryFormResource, QueryResource]>();
    endpointRequest.mockReturnValue({ patch: patchRequest, parameterised: reloadRequest, order: { get: () => Promise.resolve({}) } });
    patchRequest.mockReturnValue(patch);
    postRequest.mockReturnValue(post);
    viewRequest.mockReturnValue(view);
    reloadRequest.mockReturnValue(reload);
    findRequest.mockReturnValue(reload);
    loadForm.mockImplementation((resource:QueryResource) => resource === queryA ? formPreparation : formReload);
    await TestBed.configureTestingModule({
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        WorkPackagesListService,
        WorkPackagesQueryViewService,
        WorkPackageStatesInitializationService,
        WorkPackagesListChecksumService,
        WorkPackagesListInvalidQueryService,
        UrlParamsHelperService,
        PaginationService,
        WorkPackageViewPaginationService,
        WorkPackageViewFiltersService,
        WorkPackageViewSumService,
        WorkPackageViewAdditionalElementsService,
        WorkPackageViewDisplayRepresentationService,
        WorkPackageViewIncludeSubprojectsService,
        WorkPackageViewBaselineService,
        { provide: ConfigurationService, useValue: { perPageOptions: [20, 50] } },
        { provide: AuthorisationService, useValue: { initModelAuth: () => undefined } },
        { provide: TimezoneService, useValue: {} },
        { provide: WeekdayService, useValue: {} },
        { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
        { provide: CurrentUserService, useValue: { userId: '1' } },
        { provide: ToastService, useValue: toast },
        { provide: SubmenuService, useValue: menu },
        {
          provide: ApiV3Service,
          useValue: {
            queries: {
              id: endpointRequest,
              post: postRequest,
              find: findRequest,
              form: { load: loadForm },
            },
            views: { post: viewRequest },
            work_packages: { cache: { updateWorkPackage: () => undefined }, requireAll: () => Promise.resolve([]) },
          },
        },
      ],
    }).compileComponents();
    service = TestBed.inject(WorkPackagesListService);
    querySpace = TestBed.inject(IsolatedQuerySpace);
    initialization = TestBed.inject(WorkPackageStatesInitializationService);
    querySpace.query.putValue(queryA);
    querySpace.queryForm.putValue(formA);
    TestBed.inject(WorkPackageViewPaginationService).initialize(queryA, queryA.results);
    changes = [];
    TestBed.inject(States).changes.queries.subscribe((id) => changes.push(id));
  });

  afterEach(() => { vi.restoreAllMocks(); vi.unstubAllGlobals(); });

  it('prepares without writes and patches the captured form after navigation', async () => {
    const prepared = await service.prepareSave(queryA, isCurrent);
    expect(patchRequest).not.toHaveBeenCalled();
    leave();
    const formB = form('/api/v3/queries/2/form');
    querySpace.queryForm.putValue(formB);
    const saved = query('1');
    const persisting = prepared.persist();
    expect(endpointRequest).toHaveBeenCalledExactlyOnceWith(queryA);
    expect(patchRequest).toHaveBeenCalledExactlyOnceWith(queryA, formA);
    patch.next(saved);
    expect(await persisting).toBe(saved);
    expect(querySpace.query.value).toBe(queryB);
    expect(querySpace.queryForm.value).toBe(formB);
    expect(changes).toEqual(['1']);
    expect(toast.addSuccess).toHaveBeenCalledWith('js.notice_successful_update');
    expect(navigate).not.toHaveBeenCalled();
    expect(menu.reloadSubmenu).not.toHaveBeenCalled();
    expect(reloadRequest).not.toHaveBeenCalled();
  });

  it('loads A form directly without publishing into a successor', async () => {
    querySpace.queryForm.clear();
    const preparing = service.prepareSave(queryA, isCurrent);
    expect(loadForm).toHaveBeenCalledExactlyOnceWith(queryA);
    expect(endpointRequest).toHaveBeenCalledExactlyOnceWith(queryA);
    leave();
    const formB = form('/api/v3/queries/2/form');
    querySpace.queryForm.putValue(formB);
    formPreparation.next([formA, queryA]);
    const prepared = await preparing;
    expect(querySpace.queryForm.value).toBe(formB);
    const persisting = prepared.persist();
    patch.next(queryA);
    await persisting;
    expect(patchRequest).toHaveBeenCalledWith(queryA, formA);
    expect(querySpace.query.value).toBe(queryB);
  });

  it('keeps the saved live-owner navigation and notifications without reloading', async () => {
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    patch.next(queryA);
    await persisting;
    expect(navigate).toHaveBeenCalledTimes(1);
    expect(menu.reloadSubmenu).toHaveBeenCalledWith('1', 'work_packages_sidemenu');
    expect(changes).toEqual(['1']);
    expect(reloadRequest).not.toHaveBeenCalled();
  });

  it('does not navigate if ownership changes while the patch is pending', async () => {
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    leave();
    patch.next(queryA);
    await persisting;
    expect(changes).toEqual(['1']);
    expect(navigate).not.toHaveBeenCalled();
    expect(querySpace.query.value).toBe(queryB);
  });

  it('reports saved navigation failures without rejecting successful persistence', async () => {
    navigate.mockImplementation(() => { throw new Error('navigation failed'); });
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    patch.next(queryA);
    await expect(persisting).resolves.toBe(queryA);
    expect(toast.addError).toHaveBeenCalledExactlyOnceWith('navigation failed');
    expect(changes).toEqual(['1']);
  });

  it('propagates a preparation form failure without saving or reporting twice', async () => {
    querySpace.queryForm.clear();
    const preparing = service.prepareSave(queryA, isCurrent);
    formPreparation.error(new Error('form failed'));
    await expect(preparing).rejects.toThrow('form failed');
    expect(postRequest).not.toHaveBeenCalled();
    expect(patchRequest).not.toHaveBeenCalled();
    expect(toast.addError).not.toHaveBeenCalled();
  });

  it('captures unsaved view type before query creation and preserves global success after leaving', async () => {
    queryA.id = null;
    window.history.replaceState({}, '', '/projects/demo/calendars/new');
    const prepared = await service.prepareSave(queryA, isCurrent);
    expect(queryA.name).toBe('original');
    expect(postRequest).not.toHaveBeenCalled();
    const persisting = prepared.persist();
    window.history.replaceState({}, '', '/projects/demo/boards/9');
    leave();
    post.next(created);
    expect(viewRequest).toHaveBeenCalledExactlyOnceWith({ _links: { query: { href: created.href } } }, 'work_packages_calendar');
    view.next({} as IView);
    expect(await persisting).toBe(created);
    expect(queryA.name).toBe('js.work_packages.default_queries.manually_sorted');
    expect(changes).toEqual(['3']);
    expect(toast.addSuccess).toHaveBeenCalledWith('js.notice_successful_create');
    expect(reloadRequest).not.toHaveBeenCalled();
    expect(querySpace.query.value).toBe(queryB);
  });

  it('finishes the original query/view creation after ownership changes during view creation', async () => {
    queryA.id = null;
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    post.next(created);
    leave();
    view.next({} as IView);
    expect(await persisting).toBe(created);
    expect(changes).toEqual(['3']);
    expect(reloadRequest).not.toHaveBeenCalled();
    expect(querySpace.query.value).toBe(queryB);
  });

  async function createAndStartReload() {
    queryA.id = null;
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    post.next(created);
    view.next({} as IView);
    await persisting;
    expect(reloadRequest).toHaveBeenCalledWith(expect.objectContaining({ offset: 1, pageSize: 50 }));
    expect(reloadRequest.mock.calls[0][0]).not.toHaveProperty('pa');
    expect(reloadRequest.mock.calls[0][0]).not.toHaveProperty('pp');
  }

  it('retains the captured creation page size when settings change before the save returns', async () => {
    queryA.id = null;
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    TestBed.inject(WorkPackageViewPaginationService).updateFromObject({ perPage: 20 });
    post.next(created);
    view.next({} as IView);
    await persisting;
    expect(endpointRequest).toHaveBeenCalledExactlyOnceWith('3');
    expect(reloadRequest).toHaveBeenCalledExactlyOnceWith(expect.objectContaining({ offset: 1, pageSize: 50 }));
  });

  it('abandons create reload after navigation during the query request', async () => {
    await createAndStartReload();
    const initialize = vi.spyOn(initialization, 'initialize');
    leave();
    reload.next(loaded);
    await nextTask();
    expect(loadForm).not.toHaveBeenCalled();
    expect(initialize).not.toHaveBeenCalled();
    expect(querySpace.query.value).toBe(queryB);
    expect(navigate).not.toHaveBeenCalled();
  });

  it('abandons create reload after navigation during its form request', async () => {
    await createAndStartReload();
    reload.next(loaded);
    await vi.waitFor(() => expect(loadForm).toHaveBeenCalledWith(loaded));
    leave();
    const initialize = vi.spyOn(initialization, 'initialize');
    formReload.next([loadedForm, loaded]);
    await nextTask();
    expect(initialize).not.toHaveBeenCalled();
    expect(querySpace.query.value).toBe(queryB);
    expect(navigate).not.toHaveBeenCalled();
  });

  it('initializes before applying the loaded form and accepts its own query handover', async () => {
    await createAndStartReload();
    const events:string[] = [];
    const initialize = initialization.initialize.bind(initialization);
    const updateForm = initialization.updateStatesFromForm.bind(initialization);
    vi.spyOn(initialization, 'initialize').mockImplementation((...args) => { events.push('initialize'); return initialize(...args); });
    vi.spyOn(initialization, 'updateStatesFromForm').mockImplementation((...args) => { events.push(args[1] === loadedForm ? 'loaded form' : 'prior form'); return updateForm(...args); });
    reload.next(loaded);
    await vi.waitFor(() => expect(loadForm).toHaveBeenCalledWith(loaded));
    formReload.next([loadedForm, loaded]);
    await vi.waitFor(() => expect(querySpace.queryForm.value).toBe(loadedForm));
    expect(querySpace.query.value).toBe(loaded);
    expect(events).toEqual(['initialize', 'prior form', 'loaded form']);
    expect(navigate).toHaveBeenCalledTimes(1);
    expect(menu.reloadSubmenu).toHaveBeenCalledWith('3', 'work_packages_sidemenu');
  });

  it('skips the loaded form if a synchronous initialize subscriber replaces ownership', async () => {
    await createAndStartReload();
    const updateForm = vi.spyOn(initialization, 'updateStatesFromForm');
    const subscription = querySpace.query.values$().subscribe((resource) => {
      if (resource === loaded) leave();
    });
    reload.next(loaded);
    await vi.waitFor(() => expect(loadForm).toHaveBeenCalledWith(loaded));
    formReload.next([loadedForm, loaded]);
    await vi.waitFor(() => expect(updateForm).toHaveBeenCalledWith(loaded, formA));
    expect(updateForm).not.toHaveBeenCalledWith(loaded, loadedForm);
    expect(querySpace.query.value).toBe(queryB);
    expect(querySpace.queryForm.value).toBe(formA);
    subscription.unsubscribe();
  });

  it('guards inaccessible saved-query default loading and captures project/page size', async () => {
    queryA.public = false;
    queryA.user.id = 'other';
    const prepared = await service.prepareSave(queryA, isCurrent);
    TestBed.inject(WorkPackageViewPaginationService).updateFromObject({ perPage: 20 });
    const persisting = prepared.persist();
    patch.next(queryA);
    await persisting;
    expect(findRequest).toHaveBeenCalledExactlyOnceWith({ pageSize: 50 }, undefined, '9');
    expect(changes).toEqual(['1']);
    leave();
    reload.next(loaded);
    await nextTask();
    expect(loadForm).not.toHaveBeenCalled();
    expect(querySpace.query.value).toBe(queryB);
  });

  it('initializes a live inaccessible-query fallback before its form', async () => {
    queryA.public = false;
    queryA.user.id = 'other';
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    patch.next(queryA);
    await persisting;
    querySpace.queryForm.clear();
    reload.next(loaded);
    await vi.waitFor(() => expect(loadForm).toHaveBeenCalledWith(loaded));
    formReload.next([loadedForm, loaded]);
    await vi.waitFor(() => expect(querySpace.queryForm.value).toBe(loadedForm));
    expect(querySpace.query.value).toBe(loaded);
    expect(menu.reloadSubmenu).toHaveBeenCalledWith(null, 'work_packages_sidemenu');
  });

  it('abandons the inaccessible-query fallback after its form load loses ownership', async () => {
    queryA.public = false;
    queryA.user.id = 'other';
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    patch.next(queryA);
    await persisting;
    reload.next(loaded);
    await vi.waitFor(() => expect(loadForm).toHaveBeenCalledWith(loaded));
    leave();
    const initialize = vi.spyOn(initialization, 'initialize');
    formReload.next([loadedForm, loaded]);
    await nextTask();
    expect(initialize).not.toHaveBeenCalled();
    expect(querySpace.query.value).toBe(queryB);
  });

  it('rejects creation/view failures without a service error toast', async () => {
    queryA.id = null;
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    post.next(created);
    view.error(new Error('view failed'));
    await expect(persisting).rejects.toThrow('view failed');
    expect(toast.addError).not.toHaveBeenCalled();
    expect(changes).toEqual([]);
  });

  it('reports reload failures without rejecting successful creation', async () => {
    await createAndStartReload();
    reload.error(new Error('reload failed'));
    await vi.waitFor(() => expect(toast.addError).toHaveBeenCalledExactlyOnceWith('reload failed'));
    expect(changes).toEqual(['3']);
  });

  it('propagates persistence rejection without a duplicate error toast', async () => {
    const prepared = await service.prepareSave(queryA, isCurrent);
    const persisting = prepared.persist();
    patch.error(new Error('patch failed'));
    await expect(persisting).rejects.toThrow('patch failed');
    expect(toast.addError).not.toHaveBeenCalled();
    expect(toast.addSuccess).not.toHaveBeenCalled();
  });

  it('retains legacy save notification/navigation and create query/view flows', async () => {
    const saving = service.save(queryA);
    await vi.waitFor(() => expect(patchRequest).toHaveBeenCalled());
    patch.next(queryA);
    patch.complete();
    await saving;
    await vi.waitFor(() => expect(navigate).toHaveBeenCalledTimes(1));
    queryA.id = null;
    const creating = service.create(queryA, 'legacy name');
    post.next(created);
    view.next({} as IView);
    expect(await creating).toBe(created);
    expect(postRequest).toHaveBeenCalledWith(queryA, formA);
    expect(viewRequest).toHaveBeenCalledWith(expect.anything(), 'work_packages_table');
    expect(toast.addSuccess).toHaveBeenCalledWith('js.notice_successful_create');
  });
});
