//-- copyright
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
//++

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

