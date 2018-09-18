// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {UserLinkComponent} from './user-link.component';

import {async, TestBed} from '@angular/core/testing';
import {ComponentFixture} from '@angular/core/testing/src/component_fixture';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {UserResource} from '../../../modules/hal/resources/user-resource';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';

describe('UserLinkComponent component test', () => {
  const PathHelperStub = {
    userPath: (id:string) => `/users/${id}`
  };

  const I18nStub = {
    t: (key:string, args:any) => `Author: ${args.user}`
  };

  beforeEach(async(() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        UserLinkComponent
      ],
      providers: [
        { provide: I18nService, useValue: I18nStub },
        { provide: PathHelperService, useValue: PathHelperStub },
      ]
    }).compileComponents();
  }));

  describe('inner element', function() {
    let app:UserLinkComponent;
    let fixture:ComponentFixture<UserLinkComponent>
    let element:HTMLElement;

    let user = {
      name: 'First Last',
      href: '/api/v3/users/1',
      idFromLink: '1',
    } as UserResource;

    it('should render an inner link with specified classes', function() {
      fixture = TestBed.createComponent(UserLinkComponent);
      app = fixture.debugElement.componentInstance;
      element = fixture.elementRef.nativeElement;

      app.user = user;
      fixture.detectChanges();

      const link = element.querySelector('a')!;

      expect(link.textContent).toEqual('First Last');
      expect(link.getAttribute('title')).toEqual('Author: First Last');
      expect(link.getAttribute('href')).toEqual('/users/1');
    });
  });
});
