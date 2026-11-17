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

import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { CommonModule } from '@angular/common';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen } from '@testing-library/dom';
import { WorkPackageSubjectComponent } from './wp-subject.component';
import { EditableAttributeFieldComponent } from 'core-app/shared/components/fields/edit/field/editable-attribute-field.component';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { initializeCoreDisplayFields } from 'core-app/shared/components/fields/display/display-field.initializer';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';

describe('WorkPackageSubjectComponent', () => {
  let hal:HalResourceService;
  let api:ApiV3Service;
  const schemaPath = '/api/v3/work_packages/schemas/1-1';

  beforeEach(async () => {
    const registeredFields:Record<string, EditableAttributeFieldComponent> = {};

    await TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [WorkPackageSubjectComponent, EditableAttributeFieldComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        States,
        SchemaCacheService,
        HalResourceEditingService,
        { provide: OPContextMenuService, useValue: { close: () => undefined } },
        {
          provide: I18nService,
          useValue: { t: (key:string, options?:{ attribute:string }) => options?.attribute ?? key },
        },
        { provide: ConfigurationService, useValue: { requireDoubleClickForInlineEdit: () => false } },
        {
          provide: EditFormComponent,
          useValue: {
            register: (field:EditableAttributeFieldComponent) => { registeredFields[field.fieldName] = field; },
            activate: (fieldName:string) => {
              registeredFields[fieldName].editContainer.nativeElement.innerHTML = '<input type="text">';
              return Promise.resolve();
            },
          },
        },
      ],
    }).compileComponents();

    hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', { cls: WorkPackageResource });
    api = TestBed.inject(ApiV3Service);
    await TestBed.inject(SchemaCacheService).updateValue(schemaPath, hal.createHalResourceOfClass(SchemaResource, {
      _links: { self: { href: schemaPath } },
      subject: { name: 'Subject', type: 'String', writable: true },
      type: { name: 'Type', type: 'String', writable: true },
    }, true));
    initializeCoreDisplayFields(TestBed.inject(DisplayFieldService))();
  });

  function createWorkPackage(subject:string, id = 1) {
    return hal.createHalResource<WorkPackageResource>({
      _type: 'WorkPackage',
      subject,
      _links: {
        self: { href: `/api/v3/work_packages/${id}` },
        schema: { href: schemaPath },
        update: { href: `/api/v3/work_packages/${id}/form`, method: 'post' },
      },
    });
  }

  async function render(workPackage:WorkPackageResource):Promise<ComponentFixture<WorkPackageSubjectComponent>> {
    await api.work_packages.cache.updateWorkPackage(workPackage);
    const fixture = TestBed.createComponent(WorkPackageSubjectComponent);
    fixture.componentRef.setInput('workPackage', workPackage);
    await fixture.whenStable();
    return fixture;
  }

  it('renders the work package subject as a level 2 heading', async () => {
    const subject = 'Add some angular tests for wp-subject';
    await render(createWorkPackage(subject));

    expect(screen.getByRole('heading', { level: 2, name: subject })).toBeInTheDocument();
  });

  it('keeps the accessible heading while editing', async () => {
    const subject = 'Add some angular tests for wp-subject';
    await render(createWorkPackage(subject));

    fireEvent.click(screen.getByRole('button', { name: `Subject ${subject}`}));
    await screen.findByRole('textbox');

    expect(screen.getByRole('heading', { level: 2, name: subject })).toBeInTheDocument();
  });

  it('refreshes the accessible heading after the cache republishes the same work package', async () => {
    const workPackage = createWorkPackage('Original subject');
    await render(workPackage);
    expect(screen.getByRole('heading', { level: 2, name: 'Original subject' })).toBeInTheDocument();

    workPackage.subject = 'Updated subject';
    await api.work_packages.cache.updateWorkPackage(workPackage);

    expect(await screen.findByRole('heading', { level: 2, name: 'Updated subject' })).toBeInTheDocument();
  });
});
