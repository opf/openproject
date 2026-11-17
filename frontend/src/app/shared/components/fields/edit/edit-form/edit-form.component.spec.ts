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

import { Component, inject } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { OpenprojectFieldsModule } from 'core-app/shared/components/fields/openproject-fields.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { EditingPortalService } from '../editing-portal/editing-portal-service';
import { GlobalEditFormChangesTrackerService } from '../services/global-edit-form-changes-tracker/global-edit-form-changes-tracker.service';
import { ResourceChangesetCommit } from '../services/hal-resource-editing.service';
import { EditFormComponent } from './edit-form.component';

@Component({
  template: '<edit-form [resource]="resource" (onSaved)="saved = $event.savedResource" />',
  imports: [OpenprojectFieldsModule],
})
class WorkPackageFormHostComponent {
  resource:WorkPackageResource;
  saved:WorkPackageResource|undefined;
}

describe('EditFormComponent resource output', () => {
  beforeEach(async () => {
    TestBed.overrideModule(OpenprojectFieldsModule, {
      set: { declarations: [EditFormComponent], exports: [EditFormComponent], imports: [], providers: [], schemas: [] },
    });
    await TestBed.configureTestingModule({
      imports: [WorkPackageFormHostComponent],
      providers: [
        provideHttpClient(), provideHttpClientTesting(),
        { provide: EditingPortalService, useValue: {} },
        { provide: GlobalEditFormChangesTrackerService, useValue: { addToActiveForms: vi.fn(), removeFromActiveForms: vi.fn() } },
        { provide: SchemaCacheService, useValue: {} },
        { provide: I18nService, useValue: {} },
      ],
    }).compileComponents();
  });

  it('emits the saved work-package instance through its typed template output', () => {
    const factory = TestBed.inject(HalResourceService);
    factory.registerResource('WorkPackage', { cls: WorkPackageResource });
    const original = factory.createHalResourceOfType<WorkPackageResource>('WorkPackage', { subject: 'New' });
    const saved = factory.createHalResourceOfType<WorkPackageResource>('WorkPackage', { id: 42, subject: 'Saved' });
    const change = new ResourceChangeset(original);
    const commit = new ResourceChangesetCommit(change, saved);
    const fixture = TestBed.createComponent(WorkPackageFormHostComponent);
    fixture.componentInstance.resource = original;
    fixture.detectChanges();
    const form = fixture.debugElement.query(By.directive(EditFormComponent)).injector.get(EditFormComponent);
    const output = vi.spyOn(form.onSavedEmitter, 'emit');

    form.onSaved(commit);

    expect(output).toHaveBeenCalledWith({ savedResource: saved, isInitial: true });
    expect(fixture.componentInstance.saved).toBe(saved);
  });
});

@Component({
  selector: 'op-test-edit-mode',
  template: `
    <span role="status">{{ form.editMode ? 'Editing' : 'Viewing' }}</span>
    <button type="button" (click)="form.cancel()">Cancel</button>
  `,
})
class EditModeComponent {
  readonly form = inject(EditFormComponent);
}

@Component({
  template: '',
  standalone: false,
})
class EditFormHostComponent {}

describe('EditFormComponent', () => {
  afterEach(() => vi.unstubAllGlobals());

  it('publishes edit mode to projected consumers and unregisters on destroy', async () => {
    vi.stubGlobal('OpenProject', {});
    TestBed.configureTestingModule({
      declarations: [EditFormComponent, EditFormHostComponent],
      imports: [EditModeComponent],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).overrideTemplate(EditFormHostComponent, `
      <edit-form [inEditMode]="true"><op-test-edit-mode /></edit-form>
    `);
    const tracker = TestBed.inject(GlobalEditFormChangesTrackerService);
    const register = vi.spyOn(tracker, 'addToActiveForms');
    const unregister = vi.spyOn(tracker, 'removeFromActiveForms');
    const fixture = TestBed.createComponent(EditFormHostComponent);

    await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent('Editing'));
    const form = register.mock.calls[0][0];

    // Edit actions outside the projected view can end the form asynchronously.
    await Promise.resolve().then(() => form.cancel());
    await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent('Viewing'));

    form.editMode = true;
    await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent('Editing'));
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }));
    await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent('Viewing'));

    fixture.destroy();
    expect(unregister).toHaveBeenCalledExactlyOnceWith(form);
  });
});
