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

require('core-app/angular4-test-setup');

import {async, TestBed} from '@angular/core/testing';
import {ComponentFixture} from '@angular/core/testing/src/component_fixture';
import {I18nToken, PathHelperToken} from '../../../angular4-transition-utils';
import {UserResource} from '../../../modules/hal/resources/user-resource';

describe('UserLinkComponent component test', () => {
  const I18nStub = {
    t: sinon.stub()
      .withArgs('js.label_author', { author: 'First Last' })
      .returns('Author: First Last')
  };

  const PathHelperStub = {
    userPath: sinon.stub()
      .withArgs('1')
      .returns('/users/1')
  };

  beforeEach(async(() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        UserLinkComponent
      ],
      providers: [
        { provide: I18nToken, useValue: I18nStub },
        { provide: PathHelperToken, useValue: PathHelperStub },
      ]
    }).compileComponents();
  }));

  describe('inner element', function() {
    let app:UserLinkComponent;
    let fixture:ComponentFixture<UserLinkComponent>
    let element:JQuery;

    let user = {
      name: 'First Last',
      href: '/api/v3/users/1',
      idFromLink: '1',
    } as UserResource;

    it('should render an inner link with specified classes', function() {
      fixture = TestBed.createComponent(UserLinkComponent);
      app = fixture.debugElement.componentInstance;
      element = jQuery(fixture.elementRef.nativeElement);

      app.user = user;
      fixture.detectChanges();

      const link = element.find('a');

      expect(link.text()).to.equal('First Last');
      expect(link.attr('title')).to.equal('Author: First Last');
      expect(link.attr('href')).to.equal('/users/1');
    });
  });
});





describe('userLink Directive', function () {
  var user:any, userLoadFn:any, link:any, $q, compile:any, element, scope;

  beforeEach(angular.mock.module('openproject'));

  beforeEach(inject(function ($rootScope:any, $compile:any, _$q_:any) {
    $q = _$q_;
    var html = '<user-link user="user"></user-link>';

    userLoadFn = sinon.stub().returns($q.when(true));
    user = {
      name: 'First Last',
      href: '/api/v3/users/1',
      $load: userLoadFn,
      showUser: {href: '/some/path'}
    };

    compile = function () {
      element = angular.element(html);
      scope = $rootScope.$new();
      scope.user = user;

      $compile(element)(scope);
      scope.$digest();
      link = element.find('a');
    };
  }));

  describe('when loading', function () {
    beforeEach(function () {
      compile();
    });

    it('should render the user name', function () {
      expect(link.text()).to.equal(user.name);
      expect(userLoadFn).to.have.been.called;
      expect(link.attr('href')).to.equal(user.showUser.href);
    });
  });
});

