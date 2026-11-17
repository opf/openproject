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
import { Component, input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageTypeStatusComponent } from './wp-type-status.component';

@Component({
  selector: 'op-editable-attribute-field',
  template: `
    <button type="button" [class]="wrapperClasses()"
            [attr.data-colorize]="displayFieldOptions().colorize">
      {{ fieldName() }}: {{ resource()[fieldName()]?.name }}
    </button>
  `,
})
class EditableFieldStubComponent {
  readonly fieldName = input.required<'status'|'type'>();
  readonly resource = input.required<WorkPackageResource>();
  readonly displayFieldOptions = input<Record<string, unknown>>({});
  readonly wrapperClasses = input.required<string>();
}

describe('WorkPackageTypeStatusComponent', () => {
  it('passes status and type to their editors and keeps status colorization disabled', async () => {
    await TestBed.configureTestingModule({
      imports: [EditableFieldStubComponent],
      declarations: [WorkPackageTypeStatusComponent],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();
    const hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', { cls: WorkPackageResource });
    const workPackage = (status:string, type:string) => hal.createHalResource<WorkPackageResource>({
      _type: 'WorkPackage',
      _embedded: {
        status: { _type: 'Status', name: status },
        type: { _type: 'Type', name: type },
      },
    });
    const fixture = TestBed.createComponent(WorkPackageTypeStatusComponent);
    fixture.componentRef.setInput('workPackage', workPackage('New', 'Task'));
    await fixture.whenStable();

    const status = screen.getByRole('button', { name: 'status: New' });
    expect(status).toHaveAttribute('data-colorize', 'false');
    expect(status).toHaveClass('wp-new-top-row--status');
    expect(screen.getByRole('button', { name: 'type: Task' })).toHaveClass('wp-new-top-row--type');

    fixture.componentRef.setInput('workPackage', workPackage('Resolved', 'Bug'));

    expect(await screen.findByRole('button', { name: 'status: Resolved' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'type: Bug' })).toBeInTheDocument();
  });
});
