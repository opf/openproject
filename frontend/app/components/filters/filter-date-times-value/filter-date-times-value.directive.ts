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


import {filtersModule} from '../../../angular-modules';
import {QueryFilterInstanceResource} from '../../api/api-v3/hal-resources/query-filter-instance-resource.service';
import {AbstractDateTimeValueController} from '../abstract-filter-date-time-value/abstract-filter-date-time-value.controller'

export class DateTimesValueController extends AbstractDateTimeValueController {

  constructor(protected $scope:ng.IScope,
              protected I18n:op.I18n,
              protected TimezoneService:any) {
    super($scope, I18n, TimezoneService);
  }

  public get begin() {
    return this.filter.values[0];
  }

  public set begin(val) {
    this.filter.values[0] = val || '';
  }

  public get end() {
    return this.filter.values[1];
  }

  public set end(val) {
    this.filter.values[1] = val || '';
  }

  public get lowerBoundary() {
    if (this.begin && this.TimezoneService.isValidISODateTime(this.begin)) {
      return this.TimezoneService.parseDatetime(this.begin);
    } else {
      return null;
    }
  }

  public get upperBoundary() {
    if (this.end && this.TimezoneService.isValidISODateTime(this.end)) {
      return this.TimezoneService.parseDatetime(this.end);
    } else {
      return null;
    }
  }
}

function dateTimesValue() {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      filter: '=',
    },
    templateUrl: '/components/filters/filter-date-times-value/filter-date-times-value.directive.html',
    controller: DateTimesValueController,
    bindToController: true,
    controllerAs: '$ctrl'
  };
};

filtersModule.directive('filterDateTimesValue', dateTimesValue);
