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

describe('date time Directives', function() {
  var I18n, compile, element, scope, configurationService, TimezoneService;

  var formattedDate = function() {
    var formattedDateElement = element[0];

    return formattedDateElement.innerText || formattedDateElement.textContent;
  };

  beforeEach(angular.mock.module('openproject.uiComponents', 'openproject.services'));
  beforeEach(module('openproject.templates', function($provide) {
    configurationService = {};

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(inject(function($rootScope, $compile, _I18n_, _TimezoneService_) {
    scope = $rootScope.$new();

    scope.testDateTime = "2013-02-08T09:30:26";

    compile = function(html) {
      element = $compile(html)(scope);
      scope.$digest();
    };

    TimezoneService = _TimezoneService_;

    I18n = _I18n_;

    I18n.locale = 'en';

    TimezoneService.setupLocale();
  }));

  afterEach(function() {
    I18n.locale = undefined;

    TimezoneService.setupLocale();
  });

  var shouldBehaveLikeHashTitle = function(title) {
    it('has title', function() {
      expect(angular.element(element)[0].title).to.eq(title);
    });
  };

  describe('date directive', function() {
    var html = '<op-date date-value="testDateTime"></op-date>';

    describe('without configuration', function() {
      beforeEach(function() {
        configurationService.dateFormatPresent = sinon.stub().returns(false);

        compile(html);
      });

      it('should use default formatting', function() {
        expect(formattedDate()).to.contain('02/08/2013');
      });

      shouldBehaveLikeHashTitle('02/08/2013');
    });

    describe('with configuration', function() {
      beforeEach(function() {
        configurationService.dateFormatPresent = sinon.stub().returns(true);
        configurationService.dateFormat = sinon.stub().returns("DD-MM-YYYY");

        compile(html);
      });

      it('should use user specified formatting', function() {
        expect(formattedDate()).to.contain('08-02-2013');
      });

      shouldBehaveLikeHashTitle('08-02-2013');
    });
  });

  describe('time directive', function() {
    var html = '<op-time time-value="testDateTime"></op-time>';

    describe('without configuration', function() {
      beforeEach(function() {
        configurationService.timeFormatPresent = sinon.stub().returns(false);

        compile(html);
      });

      it('should use default formatting', function() {
        expect(formattedDate()).to.contain('9:30 AM');
      });

      shouldBehaveLikeHashTitle('9:30 AM');
    });

    describe('with configuration', function() {
      beforeEach(function() {
        configurationService.timeFormatPresent = sinon.stub().returns(true);
        configurationService.timeFormat = sinon.stub().returns("HH:mm a");

        compile(html);
      });

      it('should use user specified formatting', function() {
        expect(formattedDate()).to.contain('09:30 am');
      });

      shouldBehaveLikeHashTitle('09:30 am');
    });
  });

  describe('date time directive', function() {
    var html = '<op-date-time date-time-value="testDateTime"></op-date-time>';

    var formattedDateTime = function() {
      var formattedDateElements = [element.children()[0], element.children()[1]];
      var formattedDateTime = "";

      for (var x = 0; x < formattedDateElements.length; x++) {
        formattedDateTime += (formattedDateElements[x].innerText || formattedDateElements[x].textContent) + " ";
      }

      return formattedDateTime;
    };

    describe('without configuration', function() {
      beforeEach(function() {
        configurationService.dateFormatPresent = sinon.stub().returns(false);
        configurationService.timeFormatPresent = sinon.stub().returns(false);

        scope.dateTimeValue = "2013-02-08T09:30:26";

        compile(html);
      });

      it('should use default formatting', function() {
        expect(formattedDateTime()).to.contain('02/08/2013');
        expect(formattedDateTime()).to.contain('9:30 AM');
      });

      shouldBehaveLikeHashTitle('02/08/2013 9:30 AM');
    });

    describe('with configuration', function() {
      beforeEach(function() {
        configurationService.dateFormatPresent = sinon.stub().returns(true);
        configurationService.timeFormatPresent = sinon.stub().returns(true);
        configurationService.dateFormat = sinon.stub().returns("DD-MM-YYYY");
        configurationService.timeFormat = sinon.stub().returns("HH:mm a");

        compile(html);
      });

      it('should use user specified formatting', function() {
        expect(formattedDateTime()).to.contain('08-02-2013');
        expect(formattedDateTime()).to.contain('09:30 am');
      });

      shouldBehaveLikeHashTitle('08-02-2013 09:30 am');
    });
  });
});
