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

/*jshint expr: true*/

describe('attachmentsTitle Directive', function() {
    var I18n, compile, element, rootScope, scope;

    beforeEach(angular.mock.module('openproject.workPackages.directives'));
    beforeEach(module('openproject.templates'));

    beforeEach(inject(function($rootScope, $compile, _I18n_) {
      var html;
      html = '<attachments-title attachments="attachments"></attachments-title>';

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        $compile(element)(scope);
        scope.$digest();
      };

      I18n = _I18n_;

      var stub = sinon.stub(I18n, 't');

      stub.withArgs('js.work_packages.tabs.attachments').returns('Attachments');
    }));

    afterEach(function() {
      I18n.t.restore();
    });

    describe('element', function() {
      beforeEach(function() {
        scope.attachments = [
          { filename: 'bomba' },
          { filename: 'clat' }
        ];

        compile();
      });

      it('should render element', function() {
        expect(element.prop('tagName')).to.equal('H3');
      });

      it('should render title', function() {
        expect(element.text()).to.equal('Attachments (2)');
      });
    });
});
