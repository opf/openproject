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

import { ApplicationRef, ComponentRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { ComponentPortal, DomPortalOutlet } from '@angular/cdk/portal';
import { waitFor } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { buildTable, TableHarness } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { TableEditForm } from 'core-app/features/work-packages/components/wp-edit-form/table-edit-form';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { EditFieldService } from '../edit-field.service';
import { HalResourceEditingService } from '../services/hal-resource-editing.service';
import { HalResourceEditFieldHandler } from '../field-handler/hal-resource-edit-field-handler';
import { EditingPortalService } from './editing-portal-service';
import { EditFormPortalComponent } from './edit-form-portal.component';

async function flush() {
  for (let turn = 0; turn < 20; turn += 1) await Promise.resolve();
}

describe('EditingPortalService table ownership', () => {
  let harness:TableHarness;
  let form:TableEditForm;
  let external:HTMLInputElement;

  beforeEach(async () => {
    TestBed.configureTestingModule({
      declarations: [EditFormPortalComponent],
      providers: [{ provide: EditFieldService, useValue: { getSpecificClassFor: () => undefined } }],
    });
    TestBed.overrideComponent(EditFormPortalComponent, { set: { template: '' } });
    harness = buildTable({ workPackages: [{ id: '1' }], editing: {}, providers: [EditingPortalService] });
    await harness.render();
    const wp = harness.injector.get(States).workPackages.get('1').value!;
    harness.table.editing.startEditing(wp, harness.row('1').dataset.classIdentifier!);
    form = harness.table.editing.forms['1'];
    wp.injector = harness.injector;
    const change = new ResourceChangeset(wp);
    vi.spyOn(change, 'getForm').mockResolvedValue(undefined as never);
    vi.spyOn(harness.injector.get(HalResourceEditingService), 'changeFor').mockReturnValue(change);
    external = document.createElement('input');
    document.body.appendChild(external);
  });

  afterEach(async () => {
    vi.clearAllTimers();
    vi.useRealTimers();
    await harness.destroy();
    external.remove();
    vi.restoreAllMocks();
  });

  it.each([false, true])('cancels real portal readiness before its component task (throwing blur: %s)', async (throwing) => {
    const attach = vi.spyOn(DomPortalOutlet.prototype, 'attachComponentPortal');
    const detach = vi.spyOn(DomPortalOutlet.prototype, 'detach');
    const afterView = vi.spyOn(EditFormPortalComponent.prototype, 'ngAfterViewInit');
    const notices = vi.spyOn(harness.injector.get(HalResourceNotificationService), 'handleRawError');
    const cleanupReport = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval', 'setTimeout', 'clearTimeout'] });
    const activation = form.activate('subject');
    await flush();
    expect(attach).toHaveBeenCalledOnce();
    harness.injector.get(ApplicationRef).tick();
    expect(afterView).toHaveBeenCalledOnce();
    const ref = attach.mock.results[0].value as ComponentRef<EditFormPortalComponent>;
    const handler = ref.instance.handler as HalResourceEditFieldHandler;
    expect(handler).toBeInstanceOf(HalResourceEditFieldHandler);
    form.activeFields.subject = handler;
    const destroyed = vi.fn();
    const completed = vi.fn();
    handler.onDestroy.subscribe({ next: destroyed, complete: completed });
    const detect = vi.spyOn(ref.changeDetectorRef, 'detectChanges');
    const focus = vi.spyOn(handler, 'focus');
    const blurError = new Error('retired field blur');
    if (throwing) vi.spyOn(handler, 'blurActiveField').mockImplementation(() => { throw blurError; });
    external.focus();
    harness.table.destroy();
    await vi.runAllTimersAsync();
    await expect(activation).resolves.toBeUndefined();
    expect(detach).toHaveBeenCalled();
    expect(detect).not.toHaveBeenCalled();
    expect(form.activeFields).toEqual({});
    expect(destroyed).toHaveBeenCalledOnce();
    expect(completed).toHaveBeenCalledOnce();
    expect(harness.row('1').querySelector('edit-form-portal')).toBeNull();
    expect(focus).not.toHaveBeenCalled();
    expect(external).toHaveFocus();
    expect(notices).not.toHaveBeenCalled();
    expect(cleanupReport.mock.calls).toEqual(throwing ? [['UI cleanup failed', blurError]] : []);
  });

  it('still blurs live modal focus outside the field element', async () => {
    const handler = await form.activate('subject') as HalResourceEditFieldHandler;
    external.focus();
    handler.deactivate(false);
    expect(external).not.toHaveFocus();
  });

  it('keeps replacement focus when a retired handler submit finishes', async () => {
    const handler = await form.activate('subject') as HalResourceEditFieldHandler;
    let finish!:(value:typeof form.resource) => void;
    const saved = new Promise<typeof form.resource>((resolve) => { finish = resolve; });
    const submitSpy = vi.spyOn(form, 'submit').mockReturnValue(saved);
    const submit = handler.handleUserSubmit();
    await waitFor(() => expect(submitSpy).toHaveBeenCalled());
    harness.table.destroy();
    external.focus();
    finish(form.resource);
    await submit;
    expect(external).toHaveFocus();
  });

  it('rejects before acquiring a portal for an already destroyed owner', async () => {
    const attach = vi.spyOn(DomPortalOutlet.prototype, 'attachComponentPortal');
    const service = harness.injector.get(EditingPortalService);
    const container = form.findContainer('subject')!;
    const schema = form.change.schema.ofProperty('subject')!;
    harness.table.destroy();
    await expect(service.create(container, harness.injector, form, schema, 'subject', [], harness.table.destroyRef))
      .rejects.toThrow('Edit activation cancelled');
    expect(attach).not.toHaveBeenCalled();
  });

  it('disposes a field if construction synchronously retires its owner', async () => {
    const service = harness.injector.get(EditingPortalService);
    const container = form.findContainer('subject')!;
    const schema = form.change.schema.ofProperty('subject')!;
    const attach = vi.spyOn(DomPortalOutlet.prototype, 'attachComponentPortal');
    const toggle = container.classList.toggle.bind(container.classList);
    vi.spyOn(container.classList, 'toggle').mockImplementation((...args) => {
      harness.table.destroy();
      return toggle(...args);
    });
    await expect(service.create(container, harness.injector, form, schema, 'subject', [], harness.table.destroyRef))
      .rejects.toThrow('Edit activation cancelled');
    expect(attach).not.toHaveBeenCalled();
    expect(form.activeFields).toEqual({});
  });

  it('detaches a portal released synchronously during attachment without awaiting readiness', async () => {
    const service = harness.injector.get(EditingPortalService);
    const container = form.findContainer('subject')!;
    const schema = form.change.schema.ofProperty('subject')!;
    const attached = Object.getOwnPropertyDescriptor(DomPortalOutlet.prototype, 'attachComponentPortal')!.value as DomPortalOutlet['attachComponentPortal'];
    const detach = vi.spyOn(DomPortalOutlet.prototype, 'detach');
    vi.spyOn(DomPortalOutlet.prototype, 'attachComponentPortal').mockImplementation(function attach<T>(this:DomPortalOutlet, portal:ComponentPortal<T>):ComponentRef<T> {
      const ref = attached.call(this, portal) as ComponentRef<T>;
      harness.table.destroy();
      return ref;
    });
    await expect(service.create(container, harness.injector, form, schema, 'subject', [], harness.table.destroyRef))
      .rejects.toThrow('Edit activation cancelled');
    expect(detach).toHaveBeenCalled();
    expect(container.querySelector('edit-form-portal')).toBeNull();
    expect(form.activeFields).toEqual({});
  });

  it('preserves non-table handler blur after its form closes', () => {
    const handler = new HalResourceEditFieldHandler(harness.injector, form, 'subject', form.change.schema.ofProperty('subject'), form.findContainer('subject')!, harness.injector.get(PathHelperService), []);
    external.focus();
    handler.deactivate(false);
    expect(external).not.toHaveFocus();
  });
});
