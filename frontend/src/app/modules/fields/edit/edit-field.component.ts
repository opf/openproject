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

import {ChangeDetectorRef, Component, Inject, InjectionToken, Injector, OnDestroy, OnInit} from "@angular/core";
import {WorkPackageEditFieldHandler} from "core-components/wp-edit-form/work-package-edit-field-handler";
import {EditField} from "core-app/modules/fields/edit/edit.field.module";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {IEditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler.interface";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {IWorkPackageEditingServiceToken} from "core-components/wp-edit-form/work-package-editing.service.interface";
import {WorkPackageEditingService} from "core-components/wp-edit-form/work-package-editing-service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";

export const OpEditingPortalFieldToken = new InjectionToken('wp-editing-portal--field');
export const OpEditingPortalHandlerToken = new InjectionToken('wp-editing-portal--handler');

@Component({
  template: ''
})
export class EditFieldComponent implements OnDestroy {
  constructor(readonly I18n:I18nService,
              @Inject(IWorkPackageEditingServiceToken) protected wpEditing:WorkPackageEditingService,
              @Inject(OpEditingPortalFieldToken) readonly field:EditField,
              @Inject(OpEditingPortalHandlerToken) readonly handler:IEditFieldHandler,
              readonly cdRef:ChangeDetectorRef,
              readonly injector:Injector) {
    this.initialize();

    this.wpEditing.state(this.field.resource.id)
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((changeset) => {
        if (!this.changeset.empty && this.changeset.wpForm.hasValue()) {
          const fieldSchema = changeset.wpForm.value!.schema[this.field.name];

          if (!fieldSchema) {
            return handler.deactivate(false);
          }

          this.field.schema = fieldSchema;
          this.field.resource = changeset.workPackage;
          this.initialize();
          this.cdRef.markForCheck();
        }
      });
  }

  ngOnDestroy() {
    // Nothing to do
  }

  protected initialize() {
    // Allow subclasses to create post-constructor initialization
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

  public get changeset() {
    return this.field.changeset;
  }
}
