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

describe('optionsDropdown Directive', function() {
    var compile, element, rootScope, scope, Query, I18n, AuthorisationService, stateParams = {};

    beforeEach(module('openproject.models',
                      'openproject.workPackages',
                      'openproject.api',
                      'openproject.layout',
                      'openproject.services'));
    beforeEach(module('openproject.templates', function($provide) {
      var configurationService = {};

      configurationService.isTimezoneSet = sinon.stub().returns(false);

      $provide.constant('$stateParams', stateParams);
      $provide.constant('ConfigurationService', configurationService);
    }));

    beforeEach(module('openproject.templates', function($provide) {
      var state = { go: function() { return false; } };
      $provide.value('$state', state);
    }));

    beforeEach(inject(function($rootScope, $compile) {
      var optionsDropdownHtml;
      optionsDropdownHtml = '<div id="toolbar"><button has-dropdown-menu="" target="SettingsDropdownMenu" locals="query"></button></div>';

      element = angular.element(optionsDropdownHtml);
      rootScope = $rootScope;
      scope = $rootScope.$new();
      compile = function() {
        angular.element(document).find('body').append(element);
        $compile(element)(scope);
        element.find('button').click();
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
      element.remove();
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
          var saveAsLink = element.find('a[ng-click="showSaveAsModal($event)"]').first();
          expect(saveAsLink.hasClass('inactive')).to.be.ok;
        });

        context('share option', function() {
          beforeEach(function() {
            var query = new Query({
              id: 1
            });
            scope.query = query;
            AuthorisationService.initModelAuth('query', {
              create: '/queries'
            });
            compile();
          });

          it('should check with AuthorisationService when called', function() {
            var shareLink = element.find('a[ng-click="showShareModal($event)"]').first();
            sinon.spy(AuthorisationService, "can");
            shareLink.click();
            expect(AuthorisationService.can).to.have.been.called;
          });
        });
        it('should not open save as modal', function() {
          var saveAsLink = element.find('a[ng-click="showSaveAsModal($event)"]').first();
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
          var saveAsLink = element.find('a[ng-click="showSaveAsModal($event)"]').first();
          saveAsLink.click();

          expect(jQuery('.ng-modal-window').length).to.equal(1);
          var modal = jQuery(jQuery('.ng-modal-window')[0]);
          expect(modal.find('h3').text()).to.equal('Save as');
        });
      });

    });
});
