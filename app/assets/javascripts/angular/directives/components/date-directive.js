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

// TODO move to UI components
var uiComponents = angular.module('openproject.uiComponents')

uiComponents.directive('date', ['I18n', 'TimezoneService', 'ConfigurationService', function(I18n, TimezoneService, ConfigurationService) {
  return {
    restrict: 'EA',
    replace: false,
    scope: { dateValue: '=' },
    template: '<span>{{date}}</span>',
    link: function(scope, element, attrs) {
      if (ConfigurationService.dateFormatPresent()) {
        scope.date = TimezoneService.parseDate(scope.dateValue).format(ConfigurationService.dateFormat());
      } else {
        moment.lang(I18n.locale);

        scope.date = TimezoneService.parseDate(scope.dateValue).format('L');
      }
    }
  };
}]);

uiComponents.directive('time', ['I18n', 'TimezoneService', 'ConfigurationService', function(I18n, TimezoneService, ConfigurationService) {
  return {
    restrict: 'EA',
    replace: false,
    scope: { timeValue: '=' },
    template: '<span>{{time}}</span>',
    link: function(scope, element, attrs) {
      if (ConfigurationService.timeFormatPresent()) {
        scope.time = TimezoneService.parseDate(scope.timeValue).format(ConfigurationService.timeFormat());
      } else {
        moment.lang(I18n.locale);

        scope.time = TimezoneService.parseDate(scope.timeValue).format('LT');
      }
    }
  };
}]);

uiComponents.directive('dateTime', function($compile) {
  return {
    restrict: 'EA',
    replace: false,
    scope: { dateTimeValue: '=' },
    template: '<date date-value="dateTimeValue"></date> <time time-value="dateTimeValue"></time>',
    link: function(scope, element, attrs) {
      $compile(element.contents())(scope);
    }
  };
});
