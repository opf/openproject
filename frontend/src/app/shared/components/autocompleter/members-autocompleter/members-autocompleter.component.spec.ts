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
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { NgSelectModule } from '@ng-select/ng-select';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { States } from 'core-app/core/states/states.service';
import { OpenprojectAutocompleterModule } from '../openproject-autocompleter.module';
import { MembersAutocompleterComponent } from './members-autocompleter.component';

describe('MembersAutocompleterComponent', () => {
  it('offers matching principals and enables placeholder creation when permission arrives', async () => {
    const permission = new Subject<boolean>();
    const hasCapabilities$ = vi.fn<CurrentUserService['hasCapabilities$']>().mockReturnValue(permission);
    TestBed.configureTestingModule({
      declarations: [MembersAutocompleterComponent],
      imports: [CommonModule, FormsModule, NgSelectModule, OpenprojectAutocompleterModule],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        States,
        PrincipalsResourceService,
        { provide: CurrentUserService, useValue: { hasCapabilities$ } },
      ],
    });
    const http = TestBed.inject(HttpTestingController);
    const fixture = TestBed.createComponent(MembersAutocompleterComponent);
    fixture.componentRef.setInput('principalType', 'placeholder_user');
    fixture.componentRef.setInput('url', '/projects/example/members/available');
    fixture.componentRef.setInput('focusDirectly', false);
    fixture.componentRef.setInput('deferFetchUntilOpened', true);
    fixture.componentRef.setInput('debounceTimeMs', 0);
    fixture.componentRef.setInput('appendTo', '');
    fixture.componentRef.setInput('virtualScroll', false);
    fixture.componentRef.setInput('bindLabel', 'name');
    await fixture.whenStable();
    expect(hasCapabilities$).toHaveBeenCalledExactlyOnceWith('placeholder_users/create', 'global');

    const input = screen.getByRole('combobox');
    fireEvent.keyDown(input, { key: 'ArrowDown', keyCode: 40 });
    (await waitFor(() => http.expectOne((req) => req.params.get('q') === ''))).flush([]);
    fireEvent.input(input, { target: { value: 'Taylor' } });
    const request = await waitFor(() => http.expectOne((req) => req.params.get('q') === 'Taylor'));
    request.flush([{ id: '1', name: 'Taylor Example', href: '/api/v3/placeholder_users/1' }]);
    const option = await screen.findByRole('option', { name: /Taylor Example/ });
    expect(option).toBeVisible();
    expect(option).toHaveTextContent('Taylor Example');
    expect(screen.queryByText(/placeholder_add_tag/)).not.toBeInTheDocument();

    permission.next(true);
    expect(await screen.findByText(/placeholder_add_tag/)).toBeVisible();

    fixture.destroy();
    expect(permission.observed).toBe(false);
    http.verify();
  });
});
