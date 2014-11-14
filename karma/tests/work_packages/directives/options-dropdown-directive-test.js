//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe('optionsDropdown Directive', function() {
    var compile, element, rootScope, scope, Query, I18n, stateParams = {};

    beforeEach(angular.mock.module('openproject.workPackages.directives'));
    beforeEach(module('openproject.models',
                      'openproject.workPackages.controllers',
                      'openproject.api',
                      'openproject.layout',
                      'openproject.services'));
    beforeEach(module('templates', function($provide) {
      var configurationService = new Object();

      configurationService.isTimezoneSet = sinon.stub().returns(false);

      $provide.constant('$stateParams', stateParams);
      $provide.constant('ConfigurationService', configurationService);
    }));

    beforeEach(module('templates', function($provide) {
      var state = { go: function() { return false; } };
      $provide.value('$state', state);
    }));

    beforeEach(inject(function($rootScope, $compile) {
      var optionsDropdownHtml;
      optionsDropdownHtml = '<div options-dropdown><a href ng-click="showSaveAsModal($event)" ng-class="{\'inactive\': query.isNew()}"></a></div>';

      element = angular.element(optionsDropdownHtml);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    beforeEach(inject(function(_AuthorisationService_, _Query_, _I18n_){
      AuthorisationService = _AuthorisationService_;
      Query = _Query_;

      I18n = _I18n_;

      var stub = sinon.stub(I18n, 't');

      stub.withArgs('js.label_save_as').returns('Save as');
    }));

    afterEach(function() {
      I18n.t.restore();
    });

    describe('element', function() {

      it('should render a div', function() {
        expect(element.prop('tagName')).to.equal('DIV');
      });

      describe('inactive options', function(){
        beforeEach(function(){
          var query = new Query({
          });
          scope.query = query;

          compile();
        });

        it('should have an inactive save as option', function() {
          var saveAsLink = element.find('a').first();
          expect(saveAsLink.hasClass('inactive')).to.be.ok;
        });

        context('share option', function() {
          beforeEach(function() {
            optionsDropdownHtml = '<div options-dropdown><a class="publicize-or-star-link" href ng-click="showShareModal($event)" ng-class="{\'inactive\': (cannot(\'query\', \'publicize\') && cannot(\'query\', \'star\'))}"></a></div>';
            var query = new Query({
              id: 1
            });
            scope.query = query;
            AuthorisationService.initModelAuth('query', {
              create: '/queries'
            });
            element = angular.element(optionsDropdownHtml);
            compile();
          });

          it('should check with AuthorisationService when called', function() {
            var shareLink = element.find('.publicize-or-star-link').first();
            sinon.spy(AuthorisationService, "can");
            shareLink.click();
            expect(AuthorisationService.can).to.have.been.called;
          });
        });
        it('should not open save as modal', function() {
          var saveAsLink = element.find('a').first();
          saveAsLink.click();

          expect(jQuery('.ng-modal-window').length).to.equal(0);
        });

      });

      describe('active options', function(){
        beforeEach(function(){
          var query = new Query({
            id: 1
          });
          scope.query = query;
          AuthorisationService.initModelAuth('query', {
            create: '/queries'
          });

          compile();
        });

        it('should have an active save as option', function() {
          var saveAsLink = element.find('a').first();
          expect(saveAsLink.hasClass('inactive')).to.not.be.ok;
        });

        it('should open save as modal', function() {
          var saveAsLink = element.find('a').first();
          saveAsLink.click();

          expect(jQuery('.ng-modal-window').length).to.equal(1);
          var modal = jQuery(jQuery('.ng-modal-window')[0]);
          expect(modal.find('h3').text()).to.equal('Save as');
        });
      });

    });
});
