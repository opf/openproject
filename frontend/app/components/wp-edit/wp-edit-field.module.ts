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

abstract class WorkPackageEditField {
  public abstract get displayType():string;

  public get value() {
    return this.workPackage[this.fieldName];
  }

  public get writable():boolean {
    return this.fieldSchema.writable;
  }

  protected get fieldSchema() {
    return this.workPackage.schema[this.fieldName];
  }

  constructor(public workPackage:op.WorkPackage,
                      public fieldName:string) {
  }
}

class WorkPackageTextField extends WorkPackageEditField {
  public get displayType():string {
    return 'text';
  }
}

class WorkPackageSelectField extends WorkPackageEditField {
  //TODO Use schema value type instead of any
  protected _allowedValues:any[];

  public get displayType():string {
    return 'select';
  }

  public get allowedValues():any[] {
    return this._allowedValues;
  }

  constructor(workPackage, fieldName) {
    super(workPackage, fieldName);

    this._allowedValues = this.fieldSchema.embedded.allowedValues.map(value => value.data());
    console.log('work package', workPackage);
    console.log('wp data', workPackage.data());
    console.log('allowed values', this.allowedValues);
  }
}

export class WorkPackageEditFieldFactory {

  //TODO: Make the type map configurable
  protected static typeMap = {
    String: WorkPackageTextField,
    Priority: WorkPackageSelectField,
    Status: WorkPackageSelectField,
    Type: WorkPackageSelectField
  };

  public static create(workPackage, fieldName:string):WorkPackageEditField {
    let type = workPackage.schema[fieldName].type;
    let typeMap = WorkPackageEditFieldFactory.typeMap;

    console.log('wp field schema', workPackage.schema[fieldName]);

    if (!type in typeMap) {
      return new WorkPackageTextField(workPackage, fieldName);
    }

    return new WorkPackageEditFieldFactory.typeMap[type](workPackage, fieldName);
  }
}
