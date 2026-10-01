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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { CommonModule } from '@angular/common';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
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
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

describe('WorkPackageSubjectComponent', () => {
  beforeEach(async () => {
    const schemaStub = {
      ofProperty: () => ({ type: 'String' }),
      isAttributeEditable: () => true,
    };

    const registeredFields:Record<string, EditableAttributeFieldComponent> = {};

    await TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [WorkPackageSubjectComponent, EditableAttributeFieldComponent],
      providers: [
        { provide: ApiV3Service, useValue: {} },
        { provide: OPContextMenuService, useValue: { close: () => undefined } },
        { provide: States, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: SchemaCacheService, useValue: { of: () => schemaStub } },
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
        {
          provide: HalResourceEditingService,
          useValue: {
            temporaryEditResource: (resource:HalResource) => ({ values$: () => of(resource) }),
            typedState: () => ({ hasValue: () => false }),
          },
        },
      ],
    }).compileComponents();

    initializeCoreDisplayFields(TestBed.inject(DisplayFieldService))();
  });

  function render(wpOverrides:Partial<WorkPackageResource> = {}):ComponentFixture<WorkPackageSubjectComponent> {
    const fixture = TestBed.createComponent(WorkPackageSubjectComponent);
    fixture.componentInstance.workPackage = { subject: 'Some subject', ...wpOverrides } as WorkPackageResource;
    fixture.detectChanges();
    return fixture;
  }

  it('renders the work package subject as a level 2 heading', () => {
    const subject = 'Add some angular tests for wp-subject';
    render({ subject });

    expect(screen.getByRole('heading', { level: 2, name: subject })).toBeInTheDocument();
  });

  it('keeps the accessible heading while editing', async () => {
    const subject = 'Add some angular tests for wp-subject';
    render({ subject });

    fireEvent.click(screen.getByRole('button', { name: `subject ${subject}`}));
    await screen.findByRole('textbox');

    expect(screen.getByRole('heading', { level: 2, name: subject })).toBeInTheDocument();
  });
});
