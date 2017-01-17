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

export class FilterModelBase {
  readonly name:string;
  readonly operator:string;
  readonly type:string;
  readonly legacySchema:{
    multipleValueFilterOperators:Array<string>,
    selectableFilterTypes:Array<string>,
    operatorsNotRequiringValues:Array<string>
  };

  constructor(name:string, operator:string, type:string, legacySchema:any) {
    this.name = name;
    this.operator = operator;
    this.type = type;
    this.legacySchema = legacySchema;
  }

  toParams() {
    var params = {};

    params['op[' + this.name + ']'] = this.operator;
    params['v[' + this.name + '][]'] = this.getValuesAsArray();

    return params;
  }

  getValuesAsArray() {
    throw new Error('not implemented');
  }

  pruneValues() {}

  isSingleInputField () {
    return !this.isSelectInputField() &&
      this.legacySchema.multipleValueFilterOperators.indexOf(this.operator) === -1;
  }

  isSelectInputField() {
    return this.legacySchema.selectableFilterTypes.indexOf(this.type) !== -1;
  }

  requiresValues() {
    return this.legacySchema.operatorsNotRequiringValues.indexOf(this.operator) === -1;
  }

  isConfigured() {
    return this.operator && (this.hasValues() || !this.requiresValues());
  }

  hasValues() {
    return false;
  }
}
