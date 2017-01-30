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

import {FilterModelBase} from '../models/filter_model_base';
import {DatetimeRangeFilterModel} from '../models/datetime_range_filter_model';
import {LegacyFilterModel} from '../models/legacy_filter_model';

export class FilterModelFactory {

  private _legacySchema:any;
  private _configurationService:any;

  constructor(legacySchema:any, configurationService:any) {
    this._legacySchema = legacySchema;
    this._configurationService = configurationService;
  }

  createNewInstance(type: string, name:string, operator:string):FilterModelBase {
    return this.createNewInstanceFromData({
      type: type,
      name: name,
      operator: operator
    });
  }

  createNewInstanceFromData(data) {
    let result = null;
    switch (data.type) {
      // TODO:coy:refactor datetime_past to just datetime
      case 'datetime_past':
        switch (data.operator) {
          case '=d':
          case '<>d':
            if (!data.values) {
              data.values = [undefined, undefined, this._configurationService.timezone()];
            }
            result = new DatetimeRangeFilterModel(data, this._legacySchema);
            break;
          default:
            result = new LegacyFilterModel(data, this._legacySchema);
        }
        break;
      default:
        result = new LegacyFilterModel(data, this._legacySchema);
    }
    return result;
  }
}
