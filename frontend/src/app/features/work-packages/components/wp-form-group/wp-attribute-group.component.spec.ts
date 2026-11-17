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

import { CommonModule } from '@angular/common';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { Component, Injector, input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import { ResourceChangesetCommit } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { GroupDescriptor } from '../wp-single-view/wp-single-view.component';
import { WorkPackageFormAttributeGroupComponent } from './wp-attribute-group.component';

@Component({
  selector: 'op-editable-attribute-field',
  template: '{{ resource()[fieldName()] }}',
})
class EditableFieldStubComponent {
  readonly fieldName = input.required<string>();
  readonly resource = input.required<WorkPackageResource>();
  readonly isDropTarget = input(false);
}

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector -- Matches the production child.
  selector: 'wp-replacement-label',
  template: '<ng-content />',
})
class ReplacementLabelStubComponent {
  readonly fieldName = input.required<string>();
}

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector -- Matches the production child.
  selector: 'attribute-help-text',
  template: '',
})
class AttributeHelpTextStubComponent {
  readonly attribute = input.required<string>();
  readonly attributeScope = input.required<string>();
}

@Component({
  selector: 'op-test-attribute-group-host',
  template: '',
  standalone: false,
})
class AttributeGroupHostComponent {
  readonly workPackage = input.required<WorkPackageResource>();
  readonly group = input.required<GroupDescriptor>();
}

describe('WorkPackageFormAttributeGroupComponent', () => {
  beforeEach(async () => {
    vi.stubGlobal('OpenProject', {});
    await TestBed.configureTestingModule({
      imports: [CommonModule, EditableFieldStubComponent, ReplacementLabelStubComponent, AttributeHelpTextStubComponent],
      declarations: [AttributeGroupHostComponent, EditFormComponent, WorkPackageFormAttributeGroupComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        SchemaCacheService,
        States,
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    }).overrideTemplate(AttributeGroupHostComponent, `
    <edit-form [resource]="workPackage()" [inEditMode]="true">
      <wp-attribute-group [workPackage]="workPackage()" [group]="group()" />
    </edit-form>
  `).compileComponents();
  });

  afterEach(() => vi.unstubAllGlobals());

  it('hides read-only attributes while editing and shows them when the form finishes saving', async () => {
    const hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', { cls: WorkPackageResource });
    const workPackage = hal.createHalResource<WorkPackageResource>({
      _type: 'WorkPackage',
      subject: 'Fix the login flow',
      createdAt: 'Yesterday',
      _links: { self: { href: '/api/v3/work_packages/1' } },
    });
    const injector = TestBed.inject(Injector);
    const members = [
      { name: 'subject', label: 'Subject', writable: true },
      { name: 'createdAt', label: 'Created', writable: false },
    ].map(({ name, label, writable }) => {
      const field = new DisplayField(name, { injector, container: 'single-view', options: {} });
      field.apply(workPackage, { name: label, type: 'String', writable, hasDefault: false });
      return { name, label, field, spanAll: false, multiple: false };
    });
    const group:GroupDescriptor = { name: 'Details', id: 'details', isolated: false, type: 'attribute', members };
    const fixture = TestBed.createComponent(AttributeGroupHostComponent);
    fixture.componentRef.setInput('workPackage', workPackage);
    fixture.componentRef.setInput('group', group);
    await fixture.whenStable();

    expect(screen.getByText('Fix the login flow')).toBeInTheDocument();
    expect(screen.queryByText('Created')).not.toBeInTheDocument();
    expect(screen.queryByText('Yesterday')).not.toBeInTheDocument();

    const form = fixture.debugElement.query(By.directive(EditFormComponent)).injector.get(EditFormComponent);
    const commit = new ResourceChangesetCommit(new ResourceChangeset(workPackage), workPackage);
    await Promise.resolve().then(() => form.onSaved(commit));

    expect(await screen.findByText('Created')).toBeInTheDocument();
    expect(screen.getByText('Yesterday')).toBeInTheDocument();
    expect(screen.getByText('Fix the login flow')).toBeInTheDocument();
  });
});
