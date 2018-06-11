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

import {Component, Inject, InjectionToken, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {EditField} from 'core-app/modules/fields/edit/edit.field.module';
import {IEditFieldHandler} from 'core-app/modules/fields/edit/editing-portal/edit-field-handler.interface';
import {IFieldSchema} from 'core-app/modules/fields/field.base';
import {WorkPackageChangeset} from 'core-components/wp-edit-form/work-package-changeset';

export const OpEditingPortalFieldToken = new InjectionToken('wp-editing-portal--field');
export const OpEditingPortalHandlerToken = new InjectionToken('wp-editing-portal--handler');

@Component({
  template: ''
})
export class EditFieldComponent {
  constructor(readonly I18n:I18nService,
              @Inject(OpEditingPortalFieldToken) readonly field:EditField,
              @Inject(OpEditingPortalHandlerToken) readonly handler:IEditFieldHandler,
              readonly injector:Injector) {
    this.initialize();
  }

  protected initialize() {
  }

  public get value() {
    return this.field.value;
  }

  public set value(val:any) {
    this.field.value = val;
  }

  public get name() {
    return this.field.name;
  }

  public get schema():IFieldSchema {
    return this.field.schema;
  }

  public get changeset():WorkPackageChangeset {
    return this.field.changeset;
  }
}
