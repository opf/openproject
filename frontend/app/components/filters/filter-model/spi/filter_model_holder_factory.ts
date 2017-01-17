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

import {FilterModelHolder} from './filter_model_holder';
import {FilterModelFactory} from './filter_model_factory';

export class FilterModelHolderFactory {
  private _filterModelFactory:FilterModelFactory;

  constructor(legacySchema:any, configurationService:any) {
    this._filterModelFactory = new FilterModelFactory(legacySchema, configurationService);
  }

  createNewInstance(type:string, name:string, operator?:string) {
    let result = new FilterModelHolder(this._filterModelFactory, type, name);
    result.operator = operator;
    return result;
  }

  createNewInstanceFromNewData(data) {
    return this.createNewInstance(data.type, data.name);
  }

  createNewInstanceFromPersistedData(data) {
    let model = this._filterModelFactory.createNewInstanceFromData(data);
    return new FilterModelHolder(this._filterModelFactory, model);
  }
}
