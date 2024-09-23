//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { APP_INITIALIZER, CUSTOM_ELEMENTS_SCHEMA, Injector, NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { OpenprojectEditorModule } from 'core-app/shared/components/editor/openproject-editor.module';
import { OpenprojectAttachmentsModule } from 'core-app/shared/components/attachments/openproject-attachments.module';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpSpotModule } from 'core-app/spot/spot.module';
import { AttributeHelpTextModule } from 'core-app/shared/components/attribute-help-texts/attribute-help-text.module';
import { EditFieldService } from 'core-app/shared/components/fields/edit/edit-field.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { initializeCoreEditFields } from 'core-app/shared/components/fields/edit/edit-field.initializer';
import { initializeCoreDisplayFields } from 'core-app/shared/components/fields/display/display-field.initializer';
import { FloatEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/float-edit-field.component';
import {
  MultiSelectEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/multi-select-edit-field.component';
import {
  EditFormPortalComponent,
} from 'core-app/shared/components/fields/edit/editing-portal/edit-form-portal.component';
import {
  SelectAutocompleterRegisterService,
} from 'core-app/shared/components/fields/edit/field-types/select-edit-field/select-autocompleter-register.service';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import {
  WorkPackageEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/work-package-edit-field.component';
import {
  EditableAttributeFieldComponent,
} from 'core-app/shared/components/fields/edit/field/editable-attribute-field.component';
import {
  ProjectStatusEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/project-status-edit-field.component';
import {
  PlainFormattableEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/plain-formattable-edit-field.component';
import {
  TimeEntryWorkPackageEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/te-work-package-edit-field.component';
import { AttributeValueMacroComponent } from 'core-app/shared/components/fields/macros/attribute-value-macro.component';
import { AttributeLabelMacroComponent } from 'core-app/shared/components/fields/macros/attribute-label-macro.component';
import {
  WorkPackageQuickinfoMacroComponent,
} from 'core-app/shared/components/fields/macros/work-package-quickinfo-macro.component';
import { DisplayFieldComponent } from 'core-app/shared/components/fields/display/display-field.component';
import {
  OpenprojectAutocompleterModule,
} from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import {
  BooleanEditFieldModule,
} from 'core-app/shared/components/fields/edit/field-types/boolean-edit-field/boolean-edit-field.module';
import {
  IntegerEditFieldModule,
} from 'core-app/shared/components/fields/edit/field-types/integer-edit-field/integer-edit-field.module';
import {
  TextEditFieldModule,
} from 'core-app/shared/components/fields/edit/field-types/text-edit-field/text-edit-field.module';
import {
  DateEditFieldModule,
} from 'core-app/shared/components/fields/edit/field-types/date-edit-field/date-edit-field.module';
import {
  SelectEditFieldModule,
} from 'core-app/shared/components/fields/edit/field-types/select-edit-field/select-edit-field.module';
import {
  FormattableEditFieldModule,
} from 'core-app/shared/components/fields/edit/field-types/formattable-edit-field/formattable-edit-field.module';
import {
  EditFieldControlsModule,
} from 'core-app/shared/components/fields/edit/field-controls/edit-field-controls.module';
import { ProjectEditFieldComponent } from './edit/field-types/project-edit-field.component';
import {
  HoursDurationEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/hours-duration-edit-field.component';
import { ProgressPopoverEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/progress-popover-edit-field.component';
import { OpExclusionInfoComponent } from 'core-app/shared/components/fields/display/info/op-exclusion-info.component';
import { UserEditFieldComponent } from './edit/field-types/user-edit-field.component';
import {
  DaysDurationEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/days-duration-edit-field.component';
import { CombinedDateEditFieldComponent } from './edit/field-types/combined-date-edit-field.component';
import { NgSelectModule } from '@ng-select/ng-select';
import { FormsModule } from '@angular/forms';

@NgModule({
  imports: [
    CommonModule,
    OpSharedModule,
    OpSpotModule,
    FormsModule,
    NgSelectModule,
    OpenprojectAttachmentsModule,
    OpenprojectEditorModule,
    OpenprojectModalModule,
    OpenprojectAutocompleterModule,
    AttributeHelpTextModule,
    // Input Modules
    BooleanEditFieldModule,
    IntegerEditFieldModule,
    TextEditFieldModule,
    DateEditFieldModule,
    SelectEditFieldModule,
    FormattableEditFieldModule,
    EditFieldControlsModule,
  ],
  exports: [
    EditFormPortalComponent,
    EditFormComponent,
    EditableAttributeFieldComponent,
    DisplayFieldComponent,
  ],
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: initializeCoreEditFields,
      deps: [EditFieldService, SelectAutocompleterRegisterService],
      multi: true,
    },
    {
      provide: APP_INITIALIZER,
      useFactory: initializeCoreDisplayFields,
      deps: [DisplayFieldService],
      multi: true,
    },
  ],
  declarations: [
    EditFormPortalComponent,
    HoursDurationEditFieldComponent,
    ProgressPopoverEditFieldComponent,
    OpExclusionInfoComponent,
    DaysDurationEditFieldComponent,
    FloatEditFieldComponent,
    PlainFormattableEditFieldComponent,
    MultiSelectEditFieldComponent,
    CombinedDateEditFieldComponent,
    ProjectEditFieldComponent,
    UserEditFieldComponent,
    WorkPackageEditFieldComponent,
    TimeEntryWorkPackageEditFieldComponent,
    EditFormComponent,
    DisplayFieldComponent,
    EditableAttributeFieldComponent,
    ProjectStatusEditFieldComponent,
    AttributeValueMacroComponent,
    AttributeLabelMacroComponent,

    WorkPackageQuickinfoMacroComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
export class OpenprojectFieldsModule {
  constructor(injector:Injector) {
  }
}
