//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
  var I18n, compile, element, scope, configurationService, TimezoneService, localDatetime;

  var formattedDate = function() {
    var formattedDateElement = element[0];

    return (formattedDateElement.innerText || formattedDateElement.textContent || '').trim();
  };

  beforeEach(angular.mock.module('openproject.uiComponents', 'openproject.services'));

  beforeEach(inject(function($rootScope, $compile, _I18n_, _ConfigurationService_, _TimezoneService_) {
    scope = $rootScope.$new();

    scope.testDateTime = "2013-02-08T09:30:26Z";

    compile = function(html) {
      element = $compile(html)(scope);
      scope.$digest();
    };

    TimezoneService = _TimezoneService_;
    configurationService = _ConfigurationService_;

    I18n = _I18n_;
    I18n.locale = 'en';
    TimezoneService.setupLocale();

    localDatetime = TimezoneService.parseDatetime(scope.testDateTime);
  }));

  afterEach(function() {
    I18n.locale = undefined;
    TimezoneService.setupLocale();
  });

  var shouldHaveTitle = function(title) {
    it('has title', function() {
      expect(angular.element(element)[0].title).to.eq(title);
    });
  };

  describe('date directive', function() {
    var html = '<op-date date-value="testDateTime"></op-date>';
    var expected;

    describe('without configuration', function() {
      beforeEach(function() {
        configurationService.isTimezoneSet = sinon.stub().returns(false);
        configurationService.dateFormatPresent = sinon.stub().returns(false);
        compile(html);
        expected = TimezoneService.formattedDate(localDatetime);
      });

      it('should use default formatting', function() {
        expect(formattedDate()).to.eq(expected);
        shouldHaveTitle(expected);
      });
    });

    describe('with configuration', function() {
      beforeEach(function() {
        configurationService.isTimezoneSet = sinon.stub().returns(false);
        configurationService.dateFormatPresent = sinon.stub().returns(true);
        configurationService.dateFormat = sinon.stub().returns("DD-MM-YYYY");
        expected = TimezoneService.formattedDate(localDatetime);
        compile(html);
      });

      it('should use user specified formatting', function() {
        expect(formattedDate()).to.eq(expected);
        shouldHaveTitle(expected);
      });
    });
  });

  describe('time directive', function() {
    var html = '<op-time time-value="testDateTime"></op-time>';
    var expected;

    describe('without configuration', function() {
      beforeEach(function() {
        expected = TimezoneService.formattedTime(localDatetime);
        compile(html);
      });

      it('should use default formatting', function() {
        expect(formattedDate()).to.eq(expected);
        shouldHaveTitle(expected);
      });
    });

    describe('with configuration', function() {
      beforeEach(function() {
        configurationService.isTimezoneSet = sinon.stub().returns(false);
        configurationService.timeFormatPresent = sinon.stub().returns(true);
        configurationService.timeFormat = sinon.stub().returns("HH:mm a");
        expected = TimezoneService.formattedTime(localDatetime);
        compile(html);
      });

      it('should use user specified formatting', function() {
        expect(formattedDate()).to.eq(expected);
        shouldHaveTitle(expected);
      });
    });
  });

  describe('date time directive', function() {
    var html = '<op-date-time date-time-value="testDateTime"></op-date-time>';
    var expected;

    var formattedDateTime = function() {
      var formattedDateElements = [element.children()[0], element.children()[1]];
      var formattedDateTime = "";

      for (var x = 0; x < formattedDateElements.length; x++) {
        formattedDateTime += (formattedDateElements[x].innerText || formattedDateElements[x].textContent) + " ";
      }

      return formattedDateTime.trim();
    };

    describe('without configuration', function() {
      beforeEach(function() {
        configurationService.isTimezoneSet = sinon.stub().returns(false);
        configurationService.dateFormatPresent = sinon.stub().returns(false);
        configurationService.timeFormatPresent = sinon.stub().returns(false);

        scope.dateTimeValue = "2013-02-08T09:30:26Z";
        expected = TimezoneService.formattedDatetime(localDatetime);
        compile(html);
      });

      it('should use default formatting', function() {
        expect(formattedDateTime()).to.eq(expected);
        shouldHaveTitle(expected);
      });
    });

    describe('with configuration', function() {

      beforeEach(function() {
        configurationService.isTimezoneSet = sinon.stub().returns(false);
        configurationService.dateFormatPresent = sinon.stub().returns(true);
        configurationService.timeFormatPresent = sinon.stub().returns(true);
        configurationService.dateFormat = sinon.stub().returns("DD-MM-YYYY");
        configurationService.timeFormat = sinon.stub().returns("HH:mm a");
        expected = TimezoneService.formattedDatetime(localDatetime);
        compile(html);
      });

      it('should use user specified formatting', function() {
        expect(formattedDateTime()).to.eq(expected);
        shouldHaveTitle(expected);
      });
    });
  });
});
