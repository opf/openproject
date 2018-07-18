// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

import {APP_INITIALIZER, NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {EditFieldService} from "core-app/modules/fields/edit/edit-field.service";
import {DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {initializeCoreEditFields} from "core-app/modules/fields/edit/edit-field.initializer";
import {initializeCoreDisplayFields} from "core-app/modules/fields/display/display-field.initializer";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {BooleanEditFieldComponent} from "core-app/modules/fields/edit/field-types/boolean-edit-field";
import {DateEditFieldComponent} from "core-app/modules/fields/edit/field-types/date-edit-field";
import {FormsModule} from "@angular/forms";
import {DurationEditFieldComponent} from "core-app/modules/fields/edit/field-types/duration-edit-field";
import {FloatEditFieldComponent} from "core-app/modules/fields/edit/field-types/float-edit-field";
import {IntegerEditFieldComponent} from "core-app/modules/fields/edit/field-types/integer-edit-field";
import {MultiSelectEditFieldComponent} from "core-app/modules/fields/edit/field-types/multi-select-edit-field";
import {SelectEditFieldComponent} from "core-app/modules/fields/edit/field-types/select-edit-field";
import {FormattableEditFieldComponent} from "core-app/modules/fields/edit/field-types/formattable-edit-field.component";
import {TextEditFieldComponent} from "core-app/modules/fields/edit/field-types/text-edit-field";
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import {WorkPackageEditingPortalService} from "core-app/modules/fields/edit/editing-portal/wp-editing-portal-service";
import {EditFormPortalComponent} from "core-app/modules/fields/edit/editing-portal/edit-form-portal.component";
import {EditFieldControlsComponent,} from "core-app/modules/fields/edit/field-controls/edit-field-controls.component";
import {OpenprojectAccessibilityModule} from "core-app/modules/a11y/openproject-a11y.module";

@NgModule({
  imports: [
    FormsModule,
    BrowserModule,
    OpenprojectCommonModule,
    OpenprojectAccessibilityModule,
  ],
  exports: [
    EditFieldControlsComponent,
    EditFormPortalComponent,
  ],
  providers: [
    WorkPackageEditingPortalService,
    DisplayFieldService,
    EditFieldService,
    { provide: APP_INITIALIZER, useFactory: initializeCoreEditFields, deps: [EditFieldService], multi: true },
    { provide: APP_INITIALIZER, useFactory: initializeCoreDisplayFields, deps: [DisplayFieldService], multi: true },
  ],
  declarations: [
    EditFormPortalComponent,
    EditFieldComponent,
    BooleanEditFieldComponent,
    DateEditFieldComponent,
    DurationEditFieldComponent,
    FloatEditFieldComponent,
    IntegerEditFieldComponent,
    FormattableEditFieldComponent,
    MultiSelectEditFieldComponent,
    SelectEditFieldComponent,
    TextEditFieldComponent,
    EditFieldControlsComponent,
  ],
  entryComponents: [
    EditFormPortalComponent,
    EditFieldComponent,
    BooleanEditFieldComponent,
    DateEditFieldComponent,
    DurationEditFieldComponent,
    FloatEditFieldComponent,
    IntegerEditFieldComponent,
    FormattableEditFieldComponent,
    MultiSelectEditFieldComponent,
    SelectEditFieldComponent,
    TextEditFieldComponent,
  ]
})
export class OpenprojectFieldsModule { }

