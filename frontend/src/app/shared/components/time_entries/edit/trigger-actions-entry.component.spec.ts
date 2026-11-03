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

import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { TriggerActionsEntryComponent } from './trigger-actions-entry.component';

describe('TriggerActionsEntryComponent', () => {
  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        declarations: [TriggerActionsEntryComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
          { provide: ApiV3Service, useValue: {} },
          { provide: ToastService, useValue: {} },
          { provide: PathHelperService, useValue: {} },
          { provide: TurboRequestsService, useValue: {} },
        ],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .overrideComponent(TriggerActionsEntryComponent, { set: { providers: [] } })
      .compileComponents();

    const fixture = TestBed.createComponent(TriggerActionsEntryComponent);
    fixture.detectChanges();
  });

  it.each([
    'js.button_edit',
    'js.button_delete',
  ])('labels the %s icon-only button with its tooltip', (name) => {
    const button = screen.getByRole('button', { name });
    const tooltip = screen.getByText(name, { selector: 'tool-tip' });

    expect(tooltip).toHaveAttribute('for', button.id);
  });
});
