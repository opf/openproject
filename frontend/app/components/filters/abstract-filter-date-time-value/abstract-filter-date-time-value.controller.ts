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
import {Moment} from 'moment';
import {QueryFilterInstanceResource} from '../../api/api-v3/hal-resources/query-filter-instance-resource.service';

export abstract class AbstractDateTimeValueController {
  public filter:QueryFilterInstanceResource;

  constructor(protected $scope:ng.IScope,
              protected I18n:op.I18n,
              protected TimezoneService:any) {
    _.remove(this.filter.values as string[], value => !this.TimezoneService.isValidISODateTime(value));
  }

  public abstract get lowerBoundary():Moment
  public abstract get upperBoundary():Moment

  public get filterDateModelOptions() {
    return {
        updateOn: 'default change blur',
        debounce: {'default': 400, 'change': 0, 'blur': 0}
    };
  };

  public get isTimeZoneDifferent() {
    let value = this.lowerBoundary || this.upperBoundary;

    if (!value) {
      return false;
    } else {
      return value.hours() !== 0 || value.minutes() !== 0;
    }
  }

  public get timeZoneText() {
    if (this.lowerBoundary && this.upperBoundary) {
      return this.I18n.t('js.filter.time_zone_converted.two_values',
                         { from: this.lowerBoundary.format('YYYY-MM-DD HH:mm'),
                           to: this.upperBoundary.format('YYYY-MM-DD HH:mm') });
    } else if (this.upperBoundary) {
      return this.I18n.t('js.filter.time_zone_converted.only_end',
                         { to: this.upperBoundary.format('YYYY-MM-DD HH:mm') });

    } else {
      return this.I18n.t('js.filter.time_zone_converted.only_start',
                         { from: this.lowerBoundary.format('YYYY-MM-DD HH:mm') });

    }
  }
}
