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

describe('opIcon Directive', function() {
  let compile:Function;
  let element:ng.IAugmentedJQuery;
  let html:string;

  beforeEach(angular.mock.module('openproject.uiComponents'));

  beforeEach(inject(function($rootScope:ng.IRootScopeService, $compile:ng.ICompileService) {
    html = `<op-icon icon-classes="icon-foobar icon-context"></op-icon>`;

    compile = function() {
      element = angular.element(html);
      $compile(element)($rootScope);
      $rootScope.$digest();
    };
  }));

  describe('without a title', function() {
    beforeEach(function () {
      compile();
    });

    it('should render an icon', function () {
      const i = element.find('i');
      expect(i[0].tagName.toLowerCase()).to.equal('i');
      expect(i.hasClass('icon-foobar')).to.be.true;
      expect(i.hasClass('icon-context')).to.be.true;

      expect(element.find('span').length).to.equal(0);
    });
  });

  describe('with a title', function() {
    beforeEach(function() {
      html = `<op-icon icon-title="blabla" icon-classes="icon-foobar icon-context"></op-icon>`;
      compile();
    });

    it('should render icon and title', function() {
      const i = element.find('i');
      const span = element.find('span');

      expect(i[0].tagName.toLowerCase()).to.equal('i');
      expect(i.hasClass('icon-foobar')).to.be.true;
      expect(i.hasClass('icon-context')).to.be.true;

      expect(span[0].tagName.toLowerCase()).to.equal('span');
      expect(span.text()).to.equal('blabla');
    });
  });
});
