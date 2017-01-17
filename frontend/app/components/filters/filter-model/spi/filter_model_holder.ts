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

export class FilterModelHolder {

  deactivated:Boolean = false;
  readonly type:string;
  private _name:string;
  private _operator:string;
  private _operatorModelMap:{};
  private _filterModelFactory:any;

  constructor(filterModelFactory:any, modelOrType:any, name?:string) {
    this._filterModelFactory = filterModelFactory;
    this._operatorModelMap = {};
    if (modelOrType instanceof FilterModelBase) {
      this.type = modelOrType.type;
      this.name = modelOrType.name;
      this._operator = modelOrType.operator;
      this.model = modelOrType;
    }
    else {
      this.type = modelOrType;
      this._name = name;
    }
  }

  get name() {
    return this._name;
  }

  set name(value) {
    this._name = value;
  }

  get operator() {
    return this._operator;
  }

  set operator(operator:string) {
    if (this._operator != operator) {
      this._operator = operator;
      if (this.model == undefined) {
        this.model = this._filterModelFactory.createNewInstance(this.type, this._name, operator);
      }
    }
  }

  get model() {
    return this._operatorModelMap[this._operator];
  }

  set model(model:FilterModelBase) {
    this._operatorModelMap[model.operator] = model;
  }
}
