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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { UserLinkComponent } from './user-link.component';

describe('UserLinkComponent component test', () => {
  const PathHelperStub = {
    userPath: (id:string) => `/users/${id}`,
  };

  let fixture:ComponentFixture<UserLinkComponent>;
  let element:HTMLElement;
  let user:UserResource;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [
        UserLinkComponent,
      ],
      providers: [
        { provide: PathHelperService, useValue: PathHelperStub },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(UserLinkComponent);
    element = fixture.elementRef.nativeElement;
  });

  describe('inner element', () => {
    describe('with the user having the showUserPath attribute', () => {
      beforeEach(() => {
        user = {
          name: 'First Last',
          showUserPath: '/users/1',
        } as UserResource;

        fixture.componentRef.setInput('user', user);
        fixture.detectChanges();
      });

      it('renders a link to the user', () => {
        expect(screen.getByRole('link', { name: 'First Last' })).toHaveAttribute('href', '/users/1');
      });
    });

    describe('with the user not having the showUserPath attribute', () => {
      beforeEach(() => {
        user = {
          name: 'First Last',
          showUserPath: null,
        } as UserResource;

        fixture.componentRef.setInput('user', user);
        fixture.detectChanges();
      });

      it('renders only the name', () => {
        const link = element.querySelector('a');

        expect(link).toBeNull();
        expect(element.textContent).toEqual(' First Last ');
      });
    });
  });
});
