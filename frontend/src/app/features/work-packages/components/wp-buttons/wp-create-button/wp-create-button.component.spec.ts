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

import { Directive, Input } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { WorkPackageCreateButtonComponent } from './wp-create-button.component';

@Directive({ selector: '[opTypesCreateDropdown]', standalone: false })
class TypesCreateDropdownStubDirective {
  @Input() projectIdentifier:string|null;
  @Input() dropdownActive:boolean;
  @Input() fullView:boolean;
}

const translations:Record<string, string> = {
  'js.label_create_work_package': 'Create new work package',
};

describe('WorkPackageCreateButtonComponent', () => {
  let fixture:ComponentFixture<WorkPackageCreateButtonComponent>;
  let allowed$:Subject<boolean>;
  let createPaneOpen:boolean;

  const button = () => screen.getByRole('button', { name: 'Create new work package' });

  beforeEach(async () => {
    allowed$ = new Subject();
    createPaneOpen = false;

    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [WorkPackageCreateButtonComponent, TypesCreateDropdownStubDirective],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => translations[key] ?? key } },
          { provide: CurrentUserService, useValue: { hasCapabilities$: () => allowed$ } },
          { provide: CurrentProjectService, useValue: { id: '1', identifier: 'demo' } },
          { provide: AuthorisationService, useValue: {} },
          {
            provide: UrlParamsService,
            useValue: { changed$: new Subject(), isCreatePaneOpen: () => createPaneOpen },
          },
        ],
      })
      .compileComponents();

    fixture = TestBed.createComponent(WorkPackageCreateButtonComponent);
    fixture.detectChanges();
  });

  afterEach(() => {
    fixture.destroy();
  });

  it('stays enabled until the create permission is known', () => {
    expect(button()).not.toHaveAttribute('aria-disabled');
    expect(button()).toBeEnabled();
    expect(button()).not.toHaveAccessibleDescription();
  });

  it('is aria-disabled when creating is not allowed', async () => {
    allowed$.next(false);
    await fixture.whenStable();

    expect(button()).toHaveAttribute('aria-disabled', 'true');
    expect(button()).toBeEnabled();
  });

  it('is disabled while the create pane is open', async () => {
    createPaneOpen = true;
    allowed$.next(true);
    await fixture.whenStable();

    expect(button()).not.toHaveAttribute('aria-disabled');
    expect(button()).toBeDisabled();
  });
});
