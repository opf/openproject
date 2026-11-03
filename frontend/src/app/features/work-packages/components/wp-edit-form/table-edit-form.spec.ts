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

import { HttpErrorResponse } from '@angular/common/http';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { TestBed } from '@angular/core/testing';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageCache } from 'core-app/core/apiv3/endpoints/work_packages/work-package.cache';
import { WorkPackagesActivityService } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { ApplicationRef, DestroyableInjector, Injector } from '@angular/core';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { EditingPortalService } from 'core-app/shared/components/fields/edit/editing-portal/editing-portal-service';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { HalResourceEditingService, ResourceChangesetCommit } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { buildQuery, buildTable, TableHarness, TableHarnessOptions } from '../wp-fast-table/testing/table-harness';
import { buildWorkPackage } from '../wp-fast-table/testing/work-package-fixture';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';
import { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import { wpOccurrenceKey } from '../wp-fast-table/rendered-occurrence-ledger';

function deferred<T>() {
  let resolve!:(value:T) => void;
  let reject!:(error:unknown) => void;
  const promise = new Promise<T>((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

describe('TableEditForm activation lifetime', () => {
  let harness:TableHarness;
  const resourceInjectors:DestroyableInjector[] = [];
  const mount = async (options:Partial<TableHarnessOptions> = {}) => {
    harness = buildTable({ workPackages: [{ id: '1' }], editing: {}, ...options });
    await harness.render();
    const wp = harness.injector.get(States).workPackages.get('1').value!;
    harness.table.editing.startEditing(wp, harness.row('1').dataset.classIdentifier!);
    return harness.table.editing.forms['1'];
  };
  const timers = () => vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval', 'setTimeout', 'clearTimeout'] });
  const startWait = async () => {
    for (let turn = 0; turn < 20 && vi.getTimerCount() < 2; turn += 1) await Promise.resolve();
    expect(vi.getTimerCount()).toBe(2);
  };

  afterEach(async () => {
    vi.clearAllTimers();
    vi.useRealTimers();
    await harness.destroy();
    resourceInjectors.splice(0).forEach((injector) => injector.destroy());
    vi.restoreAllMocks();
  });

  it('activates a cell that appears before the deadline and clears both timers', async () => {
    const form = await mount();
    const cell = harness.row('1').querySelector('.subject')!;
    cell.remove();
    timers();
    const activation = form.activate('subject');
    await startWait();
    await vi.advanceTimersByTimeAsync(4800);
    harness.row('1').append(cell);
    await vi.advanceTimersByTimeAsync(100);
    const handler = await activation;
    expect(handler).toBeDefined();
    handler!.focus();
    expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus();
    expect(vi.getTimerCount()).toBe(0);
  });

  it('settles a missing-cell activation silently on table destruction at 4999 ms', async () => {
    const form = await mount();
    harness.row('1').querySelector('.subject')!.remove();
    const notice = vi.spyOn(harness.injector.get(HalResourceNotificationService), 'handleRawError');
    timers();
    const activation = form.activate('subject');
    await startWait();
    await vi.advanceTimersByTimeAsync(4999);
    harness.table.destroy();
    await expect(activation).resolves.toBeUndefined();
    expect(vi.getTimerCount()).toBe(0);
    expect(notice).not.toHaveBeenCalled();
  });

  it('reports a live missing-cell timeout after exactly 5000 ms', async () => {
    const form = await mount();
    harness.row('1').querySelector('.subject')!.remove();
    const notice = vi.spyOn(harness.injector.get(HalResourceNotificationService), 'handleRawError');
    vi.spyOn(console, 'error').mockImplementation(() => undefined);
    timers();
    const activation = form.activate('subject');
    await startWait();
    await vi.advanceTimersByTimeAsync(4999);
    expect(notice).not.toHaveBeenCalled();
    await vi.advanceTimersByTimeAsync(1);
    await expect(activation).resolves.toBeUndefined();
    expect(notice).toHaveBeenCalledWith(expect.objectContaining({ message: 'Timed out waiting for edit field subject' }));
    expect(vi.getTimerCount()).toBe(0);
  });

  it.each([false, true])('settles a pending click with the correct notice and read-only state (destroyed: %s)', async (destroyed) => {
    const form = await mount();
    const activate = vi.spyOn(form, 'activate');
    const target = harness.row('1').querySelector<HTMLElement>('.subject .inline-edit--display-field')!;
    const notice = vi.spyOn(harness.injector.get(HalResourceNotificationService), 'handleRawError');
    vi.spyOn(console, 'error').mockImplementation(() => undefined);
    timers();
    fireEvent.click(target);
    const activation = activate.mock.results[0].value as ReturnType<typeof form.activate>;
    harness.row('1').querySelector('.subject')!.remove();
    await startWait();
    await vi.advanceTimersByTimeAsync(4999);
    if (destroyed) harness.table.destroy();
    await vi.advanceTimersByTimeAsync(1);
    await activation;
    expect(target.classList.contains('-read-only')).toBe(!destroyed);
    expect(notice.mock.calls.length).toBe(destroyed ? 0 : 1);
    expect(vi.getTimerCount()).toBe(0);
  });

  it('marks the clicked target read-only and reports a genuine portal failure', async () => {
    await mount();
    const error = new Error('portal failed');
    vi.spyOn(harness.injector.get(EditingPortalService), 'create').mockRejectedValue(error);
    const notice = vi.spyOn(harness.injector.get(HalResourceNotificationService), 'handleRawError');
    vi.spyOn(console, 'error').mockImplementation(() => undefined);
    const target = harness.row('1').querySelector<HTMLElement>('.subject .inline-edit--display-field')!;
    fireEvent.click(target);
    await waitFor(() => expect(target).toHaveClass('-read-only'));
    expect(notice).toHaveBeenCalledWith(error);
  });

  it('does not create a portal when schema loading succeeds after destruction', async () => {
    const schema = deferred<void>();
    const form = await mount();
    const change = form.change;
    vi.spyOn(harness.injector.get(HalResourceEditingService), 'changeFor').mockReturnValue(change);
    vi.spyOn(change.schema, 'ofProperty').mockReturnValue(null as never);
    const getForm = vi.spyOn(change, 'getForm').mockReturnValue(schema.promise as never);
    const create = vi.spyOn(harness.injector.get(EditingPortalService), 'create');
    const notice = vi.spyOn(harness.injector.get(HalResourceNotificationService), 'handleRawError');
    const activation = form.activate('subject');
    await waitFor(() => expect(getForm).toHaveBeenCalled());
    await harness.destroy();
    schema.resolve();
    await expect(activation).resolves.toBeUndefined();
    expect(create).not.toHaveBeenCalled();
    expect(notice).not.toHaveBeenCalled();
    expect(form.activeFields).toEqual({});
  });

  it('still reports a real schema failure after the injector is destroyed', async () => {
    const schema = deferred<void>();
    const form = await mount();
    const change = form.change;
    vi.spyOn(harness.injector.get(HalResourceEditingService), 'changeFor').mockReturnValue(change);
    vi.spyOn(change.schema, 'ofProperty').mockReturnValue(null as never);
    const getForm = vi.spyOn(change, 'getForm').mockReturnValue(schema.promise as never);
    const notice = vi.spyOn(harness.injector.get(HalResourceNotificationService), 'handleRawError');
    vi.spyOn(console, 'error').mockImplementation(() => undefined);
    const activation = form.activate('subject');
    await waitFor(() => expect(getForm).toHaveBeenCalled());
    await harness.destroy();
    const error = new Error('schema request failed');
    schema.reject(error);
    await expect(activation).resolves.toBeUndefined();
    expect(notice).toHaveBeenCalledWith(error, form.resource);
  });

  it('disposes a late portal without installing or focusing it', async () => {
    const form = await mount();
    const service = harness.injector.get(EditingPortalService);
    const original = service.create.bind(service);
    const portal = deferred<EditFieldHandler>();
    let created:EditFieldHandler|undefined;
    vi.spyOn(service, 'create').mockImplementation(async (...args) => {
      created = await original(...args);
      return portal.promise;
    });
    const activate = vi.spyOn(form, 'activate');
    const target = harness.row('1').querySelector<HTMLElement>('.subject .inline-edit--display-field')!;
    fireEvent.click(target);
    const activation = activate.mock.results[0].value as ReturnType<typeof form.activate>;
    await waitFor(() => expect(created).toBeDefined());
    const focus = vi.spyOn(created!, 'focus');
    harness.table.destroy();
    portal.resolve(created!);
    await expect(activation).resolves.toBeUndefined();
    expect(form.activeFields).toEqual({});
    expect(within(harness.row('1')).queryByRole('textbox')).not.toBeInTheDocument();
    expect(focus).not.toHaveBeenCalled();
    expect(target).not.toHaveClass('-read-only');
  });

  it('continues required-column activation after a valid form-destroying redraw', async () => {
    const loading = deferred<void>();
    const conditionallyLoadForm = vi.fn(() => loading.promise);
    const form = await mount({ columns: ['id'], providers: [{ provide: WorkPackagesListService, useValue: { conditionallyLoadForm } }] });
    harness.querySpace.available.columns.putValue(buildQuery(['id', 'subject'], null, false, false).columns);
    const destroy = vi.spyOn(harness.table.editing.forms['1'], 'destroy');
    const activation = form.activateWhenNeeded('subject');
    await waitFor(() => expect(conditionallyLoadForm).toHaveBeenCalled());
    loading.resolve();
    const handler = await activation as EditFieldHandler;
    handler.focus();
    expect(destroy).toHaveBeenCalled();
    expect(harness.table.destroyed).toBe(false);
    expect(harness.table.editing.forms['1']).toBe(form);
    const input = within(harness.row('1')).getByRole('textbox');
    expect(input).toHaveFocus();
    harness.table.refreshRows(harness.injector.get(States).workPackages.get('1').value!);
    expect(within(harness.row('1')).getByRole('textbox')).toBe(input);
  });

  it('starts no DOM deadline during query-form loading and cancels the late result', async () => {
    const loading = deferred<void>();
    const conditionallyLoadForm = vi.fn(() => loading.promise);
    const form = await mount({ columns: ['id'], providers: [{ provide: WorkPackagesListService, useValue: { conditionallyLoadForm } }] });
    timers();
    const activation = form.activateWhenNeeded('subject');
    await waitFor(() => expect(conditionallyLoadForm).toHaveBeenCalled());
    expect(vi.getTimerCount()).toBe(0);
    await vi.advanceTimersByTimeAsync(6000);
    harness.table.destroy();
    loading.resolve();
    await expect(activation).resolves.toBeUndefined();
    expect(harness.row('1').querySelector('.subject')).toBeNull();
    expect(vi.getTimerCount()).toBe(0);
  });

  it('skips missing-field activation when its loaded validation form arrives late', async () => {
    const form = await mount();
    const loading = deferred<FormResource>();
    const change = form.change;
    vi.spyOn(harness.injector.get(HalResourceEditingService), 'changeFor').mockReturnValue(change);
    vi.spyOn(change, 'getForm').mockReturnValue(loading.promise);
    const activate = vi.spyOn(form, 'activateWhenNeeded');
    const activation = form.activateMissingFields();
    harness.table.destroy();
    const loaded = new FormResource(harness.injector, {}, true, () => undefined, 'Form');
    loaded.validationErrors = { subject: new ErrorResource(harness.injector, {}, true, () => undefined, 'Error') };
    loading.resolve(loaded);
    await expect(activation).resolves.toEqual([]);
    expect(activate).not.toHaveBeenCalled();
  });

  it('leaves an already queued validation tick and focus inert after destruction', async () => {
    const form = await mount();
    const resource = form.resource;
    resource.injector = harness.injector;
    const change = new ResourceChangeset(resource);
    change.setValue('subject', 'Changed');
    const editing = harness.injector.get(HalResourceEditingService);
    vi.spyOn(editing, 'changeFor').mockReturnValue(change);
    const errorResource = new ErrorResource(harness.injector, {}, true, () => undefined, 'Error');
    vi.spyOn(errorResource, 'getInvolvedAttributes').mockReturnValue(['subject']);
    vi.spyOn(errorResource, 'getMessagesPerAttribute').mockReturnValue({ subject: ['Required'] });
    const error = new HalError(new HttpErrorResponse({ status: 422 }), errorResource);
    Object.assign(editing, { save: () => Promise.reject(error) });
    vi.spyOn(form, 'activateWhenNeeded').mockResolvedValue(undefined);
    const queued:(() => void)[] = [];
    vi.spyOn(window, 'queueMicrotask').mockImplementation((callback) => queued.push(callback));
    const tick = vi.spyOn(harness.injector.get(ApplicationRef), 'tick');
    await expect(form.submit()).rejects.toBe(error);
    await waitFor(() => expect(queued.length).toBeGreaterThan(0));
    tick.mockClear();
    const external = document.createElement('input');
    document.body.appendChild(external);
    external.focus();
    harness.table.destroy();
    queued.forEach((callback) => callback());
    expect(tick).not.toHaveBeenCalled();
    expect(external).toHaveFocus();
    external.remove();
  });

  it.each(['success', 'error', 'validation'])('preserves real save %s after destruction without retired UI work', async (outcome) => {
    const form = await mount({ providers: [HalResourceEditingService, HalEventsService, HookService] });
    const states = harness.injector.get(States);
    const resourceInjector = Injector.create({
      parent: TestBed.inject(Injector),
      providers: [
        { provide: States, useValue: states },
        { provide: SchemaCacheService, useValue: Object.assign(harness.injector.get(SchemaCacheService), { ensureLoaded: () => Promise.resolve() }) },
        { provide: ConfigurationService, useValue: {} },
        { provide: TimezoneService, useValue: {} },
        WorkPackagesActivityService,
        { provide: ApiV3Service, useFactory: (injector:Injector) => ({ work_packages: { cache: new WorkPackageCache(injector, states.workPackages) } }), deps: [Injector] },
      ],
    });
    resourceInjectors.push(resourceInjector);
    const source = { id: '1', subject: 'Original', _type: 'WorkPackage', _links: { self: { href: '/api/v3/work_packages/1' } } };
    const initialize = (resource:WorkPackageResource) => {
      resource.subject = (resource.$source as typeof source).subject;
      resource._type = 'WorkPackage';
      Object.assign(resource.$links, { self: Object.assign(() => Promise.resolve(resource), { $link: { href: source._links.self.href } }) });
    };
    const resource = new WorkPackageResource(resourceInjector, source, true, initialize, 'WorkPackage') as unknown as WorkPackageResource;
    const savedResource = new WorkPackageResource(resourceInjector, { ...source, subject: 'Changed' }, true, initialize, 'WorkPackage') as unknown as WorkPackageResource;
    // Shared HAL resources outlive the table injector.
    const cache = savedResource.state;
    cache.putValue(resource);
    const cachedBefore = cache.value;
    form.resource = resource;
    const editing = harness.injector.get(HalResourceEditingService);
    const change = form.change;
    change.setValue('subject', 'Changed');
    vi.spyOn(change, 'getForm').mockResolvedValue(undefined as never);
    const changeFor = vi.spyOn(editing, 'changeFor');
    const saved = deferred<WorkPackageResource>();
    const request = vi.fn(() => saved.promise);
    resource.$links = { ...resource.$links, updateImmediately: request as unknown as CallableHalLink<WorkPackageResource> };
    const commits:ResourceChangesetCommit[] = [];
    editing.committedChanges.subscribe((commit) => commits.push(commit));
    const event = vi.fn();
    harness.injector.get(HalEventsService).events$.subscribe(event);
    const notices = harness.injector.get(HalResourceNotificationService);
    const success = vi.fn();
    Object.assign(notices, { showSave: success });
    const failure = vi.spyOn(notices, 'handleRawError');
    const tick = vi.spyOn(harness.injector.get(ApplicationRef), 'tick');
    const submit = form.submit();
    const settlement = submit.then((value) => value, (error:unknown) => error);
    await waitFor(() => expect(request).toHaveBeenCalled());
    expect(change.inFlight).toBe(true);
    await harness.destroy();
    changeFor.mockImplementation(() => { throw new Error('successor changeset requested'); });
    const close = vi.spyOn(form, 'closeEditFields');
    const validation = vi.spyOn(form, 'activateWhenNeeded');
    const error = outcome === 'validation'
      ? new HalError(new HttpErrorResponse({ status: 422 }), new ErrorResource(harness.injector, {}, true, () => undefined, 'Error'))
      : new Error('save rejected');
    if (outcome === 'success') saved.resolve(savedResource);
    else saved.reject(error);
    expect(await settlement).toBe(outcome === 'success' ? savedResource : error);
    expect(change.inFlight).toBe(false);
    expect(close).not.toHaveBeenCalled();
    expect(validation).not.toHaveBeenCalled();
    expect(tick).not.toHaveBeenCalled();
    expect(success.mock.calls).toEqual(outcome === 'success' ? [[savedResource, false]] : []);
    expect(failure.mock.calls).toEqual(outcome === 'success' ? [] : [[error, resource]]);
    expect(cache.value).toBe(outcome === 'success' ? savedResource : cachedBefore);
    expect(states.workPackages.get('1').value).toBe(outcome === 'success' ? savedResource : cachedBefore);
    expect(commits.map((commit) => commit.resource)).toEqual(outcome === 'success' ? [savedResource] : []);
    const expectedEvent = expect.objectContaining({ id: '1', eventType: 'updated' });
    expect(event.mock.calls).toEqual(outcome === 'success' ? [[expectedEvent]] : []);
    expect(editing.typedState(resource).value).toBe(outcome === 'success' ? undefined : change);
    expect(change.validateCustomFields).toBe(outcome === 'success');
    expect(change.contains('subject')).toBe(outcome !== 'success');
  });
});

describe('TableEditForm origin', () => {
  let harness:TableHarness;

  afterEach(async () => {
    await harness.destroy();
  });

  it('an editor opened by click remembers the cell it opened from as origin', async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }],
      editing: {},
      productionMarkup: true,
      configuration: { keyboardNavigationEnabled: true },
    });
    await harness.render();
    const wp = harness.injector.get(States).workPackages.get('1').value!;
    harness.table.editing.startEditing(wp, harness.row('1').dataset.classIdentifier!);
    const form = harness.table.editing.forms['1'];
    const subject = harness.row('1').querySelector<HTMLTableCellElement>('td.subject')!;
    const index = Array.from(harness.row('1').cells).filter((cell) => cell.classList.contains('wp-table--navigable-cell')).indexOf(subject);

    expect(form.origin).toBeNull();
    fireEvent.mouseDown(subject, { button: 0 });
    await form.activate('subject');

    expect(index).toBeGreaterThan(-1);
    expect(form.origin).toMatchObject({ cell: index });
    harness.table.keyboardNavigation!.recordPosition({ key: 'header', cell: 0, desiredColumn: 0 });
    expect(form.origin).toMatchObject({ cell: index });

    form.closeEditFields();
    expect(form.origin).toBeNull();
  });

  describe('with a remembered position elsewhere', () => {
    const mountTwoRows = async () => {
      harness = buildTable({
        workPackages: [{ id: '1' }, { id: '2' }],
        editing: {},
        productionMarkup: true,
        configuration: { keyboardNavigationEnabled: true },
      });
      await harness.render();
      harness.table.keyboardNavigation!.recordPosition({ key: wpOccurrenceKey('2'), cell: 0, desiredColumn: 0 });
    };
    const formFor = (id:string) => {
      const wp = harness.injector.get(States).workPackages.get(id).value!;
      harness.table.editing.startEditing(wp, harness.row(id).dataset.classIdentifier!);
      return harness.table.editing.forms[id];
    };

    it('an editor activated programmatically returns focus to its own cell on cancel', async () => {
      await mountTwoRows();
      const handler = await formFor('1').activate('subject');
      handler!.focus();

      handler!.handleUserCancel();

      expect(harness.row('1').querySelector('td.subject')).toHaveFocus();
    });

    it('an editor in the inline-create row has no origin', async () => {
      await mountTwoRows();
      const row = harness.addInlineCreateRow();
      const form = harness.table.editing.forms[HAL_NEW_RESOURCE_ID];

      const handler = await form.activate('subject');

      expect(handler).toBeDefined();
      expect(row).toContainElement(within(row).getByRole('textbox'));
      expect(form.origin).toBeNull();
    });

    it('a failed activation leaves no origin behind', async () => {
      await mountTwoRows();
      vi.spyOn(harness.injector.get(EditingPortalService), 'create').mockRejectedValue(new Error('portal failed'));
      vi.spyOn(console, 'error').mockImplementation(() => undefined);
      const form = formFor('1');

      await expect(form.activate('subject')).resolves.toBeUndefined();

      expect(form.origin).toBeNull();
      vi.restoreAllMocks();
    });
  });
});

describe('TableEditForm focus return', () => {
  let harness:TableHarness;
  const outside = document.createElement('button');

  const mount = async (options:Partial<TableHarnessOptions> = {}, keyboardNavigationEnabled = true) => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      editing: {},
      productionMarkup: true,
      ...options,
      configuration: { keyboardNavigationEnabled },
    });
    await harness.render();
  };
  const subjectCell = (id = '1') => harness.row(id).querySelector<HTMLTableCellElement>('td.subject')!;
  const openEditor = async (id = '1') => {
    const display = subjectCell(id).querySelector<HTMLElement>('.inline-edit--display-field')!;
    fireEvent.mouseDown(display, { button: 0 });
    fireEvent.click(display);
    await waitFor(() => expect(within(harness.row(id)).getByRole('textbox')).toHaveFocus());
    return harness.table.editing.forms[id].activeFields.subject;
  };
  const saveAs = (subject:string, id = '1') => () => {
    const saved = buildWorkPackage({ id, subject });
    harness.injector.get(States).workPackages.get('1').putValue(saved);
    return Promise.resolve({ resource: saved, wasNew: false });
  };

  afterEach(async () => {
    outside.remove();
    await harness.destroy();
    vi.restoreAllMocks();
  });

  it('cancelling an editor opened by click returns focus to the origin cell', async () => {
    await mount();
    const handler = await openEditor();

    handler.handleUserCancel();

    expect(subjectCell()).toHaveFocus();
  });

  it('saving an editor returns focus to the origin cell after the row refresh', async () => {
    await mount({ editing: { save: saveAs('Changed') } });
    const handler = await openEditor();
    const idCell = harness.row('1').querySelector('td.id');

    await handler.handleUserSubmit();

    expect(harness.row('1').querySelector('td.id')).not.toBe(idCell);
    expect(subjectCell()).toHaveFocus();
  });

  it('an unchanged-value submit returns focus to the origin cell', async () => {
    await mount();
    const handler = await openEditor();

    await handler.handleUserSubmit();

    expect(subjectCell()).toHaveFocus();
  });

  it('a validation error keeps the editor focused', async () => {
    const errorResource = new ErrorResource(TestBed.inject(Injector), {}, true, () => undefined, 'Error');
    vi.spyOn(errorResource, 'getInvolvedAttributes').mockReturnValue(['subject']);
    vi.spyOn(errorResource, 'getMessagesPerAttribute').mockReturnValue({ subject: ['Required'] });
    const error = new HalError(new HttpErrorResponse({ status: 422 }), errorResource);
    await mount({ editing: { save: () => Promise.reject(error) } });
    const handler = await openEditor();

    await expect(handler.handleUserSubmit()).rejects.toBe(error);

    await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
  });

  it('no return when focus moved elsewhere while the save was pending', async () => {
    const save = deferred<{ resource:WorkPackageResource; wasNew:boolean }>();
    await mount({ editing: { save: () => save.promise } });
    const handler = await openEditor();
    document.body.append(outside);

    const submission = handler.handleUserSubmit();
    outside.focus();
    await saveAs('Changed')().then(save.resolve);
    await submission;

    expect(subjectCell()).not.toHaveFocus();
  });

  it('a save completing while another row\'s editor is open does not return focus', async () => {
    const save = deferred<{ resource:WorkPackageResource; wasNew:boolean }>();
    await mount({ editing: { save: () => save.promise } });
    const handler = await openEditor();

    const submission = handler.handleUserSubmit();
    await openEditor('2');
    await saveAs('Changed')().then(save.resolve);
    await submission;

    expect(within(harness.row('2')).getByRole('textbox')).toBeInTheDocument();
    expect(subjectCell()).not.toHaveFocus();
  });

  describe('while the save is pending', () => {
    const hierarchy:Partial<TableHarnessOptions> = {
      workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }],
      showHierarchies: true,
    };
    const pendingSave = async (options:Partial<TableHarnessOptions> = {}, id = '1') => {
      const save = deferred<{ resource:WorkPackageResource; wasNew:boolean }>();
      await mount({ ...options, editing: { save: () => save.promise } });
      const handler = await openEditor(id);
      const submission = handler.handleUserSubmit();
      return async () => {
        await saveAs('Changed', id)().then(save.resolve);
        await submission;
      };
    };
    const moveByPointer = (target:HTMLElement) => {
      fireEvent.mouseDown(target, { button: 0 });
      target.focus();
      fireEvent.mouseUp(target, { button: 0 });
    };

    it('does not return focus when the user moved to another cell', async () => {
      const complete = await pendingSave();
      moveByPointer(subjectCell('2'));

      await complete();

      expect(subjectCell()).not.toHaveFocus();
      expect(subjectCell('2')).toHaveAttribute('tabindex', '0');
      expect(harness.table.keyboardNavigation!.position).toMatchObject({ key: wpOccurrenceKey('2'), cell: 1 });
    });

    it('does not return focus when the user moved to another cell of the same row', async () => {
      const complete = await pendingSave();
      moveByPointer(harness.row('1').querySelector<HTMLTableCellElement>('td.id')!);

      await complete();

      expect(subjectCell()).not.toHaveFocus();
      expect(harness.row('1').querySelector('td.id')).toHaveAttribute('tabindex', '0');
      expect(harness.table.keyboardNavigation!.position).toMatchObject({ key: wpOccurrenceKey('1'), cell: 0 });
    });

    it('returns focus to the hiding parent when the origin row was collapsed', async () => {
      const complete = await pendingSave(hierarchy, '2');
      const hierarchies = harness.injector.get(WorkPackageViewHierarchiesService);

      hierarchies.collapse('1');
      await waitFor(() => expect(harness.row('2')).not.toBeVisible());
      await complete();

      expect(harness.row('1')).toHaveFocus();
      expect(harness.table.scrollContainer.querySelectorAll('[tabindex="0"]')).toHaveLength(1);
    });

    it('returns focus to the origin after a render moved the remembered position', async () => {
      const complete = await pendingSave(hierarchy, '2');
      const hierarchies = harness.injector.get(WorkPackageViewHierarchiesService);

      hierarchies.collapse('1');
      await waitFor(() => expect(harness.row('2')).not.toBeVisible());
      expect(harness.table.keyboardNavigation!.position).toMatchObject({ key: wpOccurrenceKey('1'), cell: null });
      hierarchies.expand('1');
      await waitFor(() => expect(harness.row('2')).toBeVisible());
      await complete();

      expect(subjectCell('2')).toHaveFocus();
    });
  });

  it('saving a form whose second field opened by click returns focus to the first field\'s cell', async () => {
    await mount({
      workPackages: [{ id: '1', attributes: { location: 'Here' } }, { id: '2' }],
      columns: ['id', 'subject', 'location'],
      editing: { fields: ['subject', 'location'], save: saveAs('Changed') },
    });
    const handler = await openEditor();
    const location = harness.row('1').querySelector<HTMLElement>('td.location .inline-edit--display-field')!;
    fireEvent.mouseDown(location, { button: 0 });
    fireEvent.click(location);
    await waitFor(() => expect(harness.table.editing.forms['1'].activeFields.location).toBeDefined());

    await handler.handleUserSubmit();

    expect(subjectCell()).toHaveAttribute('tabindex', '0');
    expect(harness.table.scrollContainer.querySelectorAll('[tabindex="0"]')).toHaveLength(1);
    expect(subjectCell()).toHaveFocus();
  });

  it('reset with focus=false returns nothing', async () => {
    await mount();
    await openEditor();

    harness.table.editing.forms['1'].closeEditFields();

    expect(document.body).toHaveFocus();
  });

  it('flag off: reset still focuses the cell through FocusHelper', async () => {
    await mount({}, false);
    const focus = vi.spyOn(harness.injector.get(FocusHelperService), 'focus');
    const handler = await openEditor();

    handler.handleUserCancel();

    expect(focus).toHaveBeenCalledWith(subjectCell().querySelector('.inline-edit--container'));
    expect(subjectCell()).not.toHaveFocus();
  });
});
