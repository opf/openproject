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

describe('flashMessage Directive', function() {
  var compile, element, rootScope, scope;

  beforeEach(angular.mock.module('openproject.uiComponents', function($provide) {
    var configurationService = {};

    configurationService.accessibilityModeEnabled = sinon.stub().returns(true);

    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(module('openproject.templates'));

  beforeEach(inject(function($rootScope, $compile) {
    var html = '<flash-message></flash-message>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  context('with no message', function() {
    beforeEach(function() {
      compile();
    });

    it('should render no message initially', function() {
      expect(element.text()).to.be.equal('');
    });

    it('should be hidden', function() {
      expect(element.hasClass('ng-hide')).to.be.true;
    });
  });

  context('with flash messages', function() {
    beforeEach(function() {
      compile();
    });

    describe('info message', function() {
      var message = {
        text: 'für deine Informationen',
        isError: false
      };

      beforeEach(function() {
        rootScope.$emit('flashMessage', message);
        scope.$apply();
      });

      it('should render message', function() {
        expect(element.text().trim()).to.equal('für deine Informationen');
      });

      it('should be visible', function() {
        expect(element.hasClass('ng-hide')).to.be.false;
      });

      it('should style as an info message', function() {
        expect(element.attr('class').split(' ')).to
          .include.members(['flash', 'icon-notice', 'notice']);
      });
    });

    describe('error message', function() {
      var message = {
        text: '¡Alerta! WARNING! Achtung!',
        isError: true
      };

      beforeEach(function() {
        rootScope.$emit('flashMessage', message);
        scope.$apply();
      });

      it('should render message', function() {
        expect(element.text().trim()).to.equal('¡Alerta! WARNING! Achtung!');
      });

      it('should be visible', function() {
        expect(element.hasClass('ng-hide')).to.be.false;
      });

      it('should style as an error message', function() {
        expect(element.attr('class').split(' ')).to
          .include.members(['flash', 'icon-errorExplanation', 'errorExplanation']);
      });
    });
  });
});
