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

import {FilterModelBase} from './filter_model_base';

export class DatetimeRangeFilterModel extends FilterModelBase {
  data : {
    from?:any
    until?:any
    tz?:string
  };

  constructor(data, legacySchema) {
    super(data.name, data.operator, data.type, legacySchema);
    let values = data.values || [];
    this.data = {
      from: values[0],
      until: values[1],
      tz: values[2]
    }
  }

  toParams() {
    let params = {};

    params['op[' + this.name + ']'] = this.operator;
    params['v[' + this.name + '][]'] = this.getValuesAsArray();

    return params;
  }

  getValuesAsArray() {
    return [this.data.from, this.data.until, this.data.tz];
  }

  hasValues() {
    return this.data.from != null && this.data.until != null && this.data.tz != null;
  }
}
