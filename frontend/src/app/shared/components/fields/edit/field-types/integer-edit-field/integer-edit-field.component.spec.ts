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

import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AutofocusDirective } from 'core-app/shared/directives/focus/autofocus.directive';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { IntegerEditFieldComponent } from './integer-edit-field.component';

describe('IntegerEditFieldComponent', () => {
  it('renders the initial value and subsequent changeset emissions', async () => {
    const updates = new Subject<unknown>();
    const changeset = {
      projectedResource: { value: 1 },
      schema: { ofProperty: () => ({ required: false }), mappedName: () => 'value' },
      state: { values$: () => updates },
    };
    TestBed.configureTestingModule({
      declarations: [IntegerEditFieldComponent, AutofocusDirective],
      imports: [FormsModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: FocusHelperService, useValue: { focus: vi.fn() } },
        { provide: OpEditingPortalChangesetToken, useValue: changeset },
        { provide: OpEditingPortalSchemaToken, useValue: {} },
        { provide: OpEditingPortalHandlerToken, useValue: { fieldName: 'value', htmlId: 'field-value', inFlight: false } },
      ],
    });
    const fixture = TestBed.createComponent(IntegerEditFieldComponent);
    await fixture.whenStable();
    const input = (fixture.nativeElement as HTMLElement).querySelector('input');
    expect(input).toHaveValue(1);

    changeset.projectedResource.value = 2;
    updates.next(changeset);
    await fixture.whenStable();
    expect(input).toHaveValue(2);
    updates.complete();
  });
});
