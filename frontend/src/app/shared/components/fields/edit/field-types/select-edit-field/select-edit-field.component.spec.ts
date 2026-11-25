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
import { AfterViewInit, Component, EventEmitter, Input, Output } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { waitFor } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { DynamicOutputsDirective } from 'core-app/shared/components/dynamic-component/dynamic-outputs.directive';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResourceSortingService } from 'core-app/features/hal/services/hal-resource-sorting.service';
import { OpEditingPortalChangesetToken, OpEditingPortalHandlerToken, OpEditingPortalSchemaToken } from '../../edit-field.component';
import { SelectAutocompleterRegisterService } from './select-autocompleter-register.service';
import { SelectEditFieldComponent } from './select-edit-field.component';
import { WorkPackageEditFieldComponent } from '../work-package-edit-field.component';

@Component({
  template: '<button (click)="onChange.emit(option)">Choose option</button>',
})
class AutocompleterComponent implements AfterViewInit {
  @Input() availableValues:unknown;
  @Input() appendTo:unknown;
  @Input() model:unknown;
  @Input() required:unknown;
  @Input() disabled:unknown;
  @Input() id:unknown;
  @Input() finishedLoading:unknown;
  @Input() classes:unknown;
  @Input() resource:unknown;
  @Input() typeahead:unknown;
  @Input() hideSelected:unknown;
  // eslint-disable-next-line @angular-eslint/no-output-on-prefix -- Matches the existing autocomplete output contract.
  @Output() readonly onChange = new EventEmitter<unknown>();
  // eslint-disable-next-line @angular-eslint/no-output-on-prefix -- Matches the existing autocomplete output contract.
  @Output() readonly onAfterViewInit = new EventEmitter<AutocompleterComponent>();
  readonly option = { href: '/api/v3/statuses/2', name: 'Ready' };
  openDirectly = false;

  ngAfterViewInit() { this.onAfterViewInit.emit(this); }
}

describe.each([SelectEditFieldComponent, WorkPackageEditFieldComponent])('%s dynamic autocompleter', (fieldComponent) => {
  it('connects initialization and selection outputs through the dynamic child', async () => {
    const activate = new Subject<void>();
    const projectedResource = { status: { href: '/api/v3/statuses/1', name: 'New' } };
    const schema = { type: 'Status', required: true, allowedValues: [projectedResource.status] };
    const submit = vi.fn();
    TestBed.configureTestingModule({
      imports: [CommonModule, DynamicOutputsDirective],
      declarations: [fieldComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpEditingPortalSchemaToken, useValue: schema },
        { provide: OpEditingPortalHandlerToken, useValue: {
          fieldName: 'status', htmlId: 'status-field', inFlight: false,
          $onUserActivate: activate, handleUserSubmit: submit,
        } },
        { provide: OpEditingPortalChangesetToken, useValue: {
          projectedResource, schema: { ofProperty: () => schema, mappedName: (name:string) => name },
          getForm: () => Promise.resolve(),
        } },
        { provide: SelectAutocompleterRegisterService, useValue: { getAutocompleterOfAttribute: () => AutocompleterComponent } },
        { provide: HalResourceNotificationService, useValue: {} },
        { provide: HalResourceSortingService, useValue: { sort: <T>(values:T[]) => values } },
      ],
    });
    const fixture = TestBed.createComponent(fieldComponent);
    await fixture.whenStable();
    const child = fixture.debugElement.query(By.directive(AutocompleterComponent)).componentInstance as AutocompleterComponent;
    activate.next();
    await waitFor(() => expect(child.openDirectly).toBe(true));
    (fixture.nativeElement as HTMLElement).querySelector('button')!.click();
    await fixture.whenStable();
    expect(projectedResource.status).toEqual({ href: '/api/v3/statuses/2', name: 'Ready' });
    expect(submit).toHaveBeenCalledOnce();
  });
});
