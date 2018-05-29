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

import {Component, Inject, InjectionToken, Injector} from "@angular/core";
import {WorkPackageEditFieldHandler} from "core-components/wp-edit-form/work-package-edit-field-handler";
import {EditField} from "core-app/modules/fields/edit/edit.field.module";
import {IFieldSchema} from "core-app/modules/fields/field.base";

export const OpEditingPortalLocalsToken = new InjectionToken('wp-editing-portal-locals');
export interface EditFieldLocals {
  handler:WorkPackageEditFieldHandler;
  field:any;
}

@Component({
  template: ''
})
export class EditFieldComponent {
  public handler = this.locals.handler;
  public field = this.locals.field;

  constructor(@Inject(OpEditingPortalLocalsToken) readonly locals:EditFieldLocals,
              readonly injector:Injector) {
    this.initialize();
  }

  protected initialize() {
  }

  protected get value() {
    return this.field.value;
  }

  protected set value(val:any) {
    this.field.value = val;
  }

  protected get name() {
    return this.field.name;
  }

  protected get schema():IFieldSchema {
    return this.field.schema;
  }

  protected get changeset() {
    return this.field.changeset;
  }
}
