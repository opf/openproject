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

interface OpDatetimeRangeFilterScope extends ng.IScope {
  data:{
    from:any,
    until:any,
    tz:String
  }

  withFrom?:Boolean
  withUntil?:Boolean

  untilDuration?:String

  // TODO:refactor to configuration service/settings
  inputFormatDate?:String
  inputFormatTime?:String
  displayFormatDate?:String
  displayFormatTime?:String

  withDetail?:Boolean
  withDetailLocal?:Boolean
  withDetailDisplayFormat?:String

  from?:any
  until?:any
  tz?:String
  fromLocal?:any
  untilLocal?:any
  tzLocal?:String
}

function opDatetimeRangeFilterLink(scope:OpDatetimeRangeFilterScope) {

  function toTZ(value, tz) {
    let result = undefined;
    if (value)
    {
      result = moment.tz(value, tz);
    }
    return result;
  }

  let toLocal = (value) => {
    return toTZ(value, this.ConfigurationService.timezone());
  };

  // populate detail info first
  scope.from = toTZ(scope.data.from, scope.data.tz);
  if (!scope.withUntil && scope.untilDuration && scope.data.from)
  {
    let duration = moment.duration(scope.untilDuration);
    scope.data.until = scope.from.clone().add(duration);
  }
  scope.until = toTZ(scope.data.until, scope.data.tz);
  scope.tz = scope.data.tz || this.ConfigurationService.timezone();
  scope.fromLocal = toLocal(scope.from);
  scope.untilLocal = toLocal(scope.until);
  // TODO:need to be watching timezone property, too
  scope.tzLocal = this.ConfigurationService.timezone();
  // hide detail local if both timezones are the same
  scope.withDetailLocal = scope.tz != scope.tzLocal;

  // update data and detail info on changes to the data
  scope.$watch('data.from', function (newValue, oldValue, scope:OpDatetimeRangeFilterScope) {
    scope.from = toTZ(newValue, scope.data.tz);
    scope.fromLocal = toLocal(scope.from);
    if (!scope.withUntil && scope.untilDuration && scope.from)
    {
      let duration = moment.duration(scope.untilDuration);
      scope.data.until = scope.from.clone().add(duration);
    }
  });
  scope.$watch('data.until', function (newValue, oldValue, scope:OpDatetimeRangeFilterScope) {
    scope.until = toTZ(newValue, scope.data.tz);
    scope.untilLocal = toLocal(scope.until);
  });
  scope.$watch('data.tz', function (newValue, oldValue, scope:OpDatetimeRangeFilterScope) {
    scope.tz = newValue;
  });
}

function opDatetimeRangeFilter(ConfigurationService) {
  var dependencies = {
    ConfigurationService: ConfigurationService
  };

  return {
    restrict: 'E',
    templateUrl: '/components/filters/ui/op-datetime-range-filter/op-datetime-range-filter.directive.html',
    // http://stackoverflow.com/a/33614939/3206935
    link: angular.bind(dependencies, opDatetimeRangeFilterLink),
    scope: {
      data: '=ngModel',
      withFrom: '@?',
      withUntil: '@?',
      fromTime: '@?',
      untilTime: '@?',
      targetTZ: '@?',
      withDetail: '@?',
      withDetailLocal: '=?bind'
    }
  };
}

angular
  .module('openproject')
  .directive('opDatetimeRangeFilter', opDatetimeRangeFilter);
