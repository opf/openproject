import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { ReactiveFormsModule } from "@angular/forms";
import { FormlyModule } from "@ngx-formly/core";
import { HTTP_INTERCEPTORS, HttpClientModule } from "@angular/common/http";
import { NgSelectModule } from "@ng-select/ng-select";
import { DynamicFieldGroupWrapperComponent } from "./components/dynamic-field-group-wrapper/dynamic-field-group-wrapper.component";
import { DynamicFormComponent } from "./components/dynamic-form/dynamic-form.component";
import { OpenProjectHeaderInterceptor } from "core-app/modules/hal/http/openproject-header-interceptor";
import { TextInputComponent } from './components/dynamic-inputs/text-input/text-input.component';
import { IntegerInputComponent } from './components/dynamic-inputs/integer-input/integer-input.component';
import { SelectInputComponent } from './components/dynamic-inputs/select-input/select-input.component';
import { SelectProjectStatusInputComponent } from "./components/dynamic-inputs/select-project-status-input/select-project-status-input.component";
import { NgOptionHighlightModule } from "@ng-select/ng-option-highlight";
import { BooleanInputComponent } from './components/dynamic-inputs/boolean-input/boolean-input.component';
import { DateInputComponent } from './components/dynamic-inputs/date-input/date-input.component';
import { DatePickerAdapterComponent } from './components/dynamic-inputs/date-input/components/date-picker-adapter/date-picker-adapter.component';
import { FormattableTextareaInputComponent } from './components/dynamic-inputs/formattable-textarea-input/formattable-textarea-input.component';
import { OpenprojectEditorModule } from "core-app/modules/editor/openproject-editor.module";
import { FormattableControlComponent } from './components/dynamic-inputs/formattable-textarea-input/components/formattable-control/formattable-control.component';
import { OpenprojectCommonModule } from "core-app/modules/common/openproject-common.module";
import { FormattableEditFieldModule } from "core-app/modules/fields/edit/field-types/formattable-edit-field/formattable-edit-field.module";
import { DatePickerModule } from "core-app/modules/common/op-date-picker/date-picker.module";
import { DynamicFieldWrapperComponent } from './components/dynamic-field-wrapper/dynamic-field-wrapper.component';

@NgModule({
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormlyModule.forRoot({
      types: [
        { name: 'booleanInput', component: BooleanInputComponent },
        { name: 'integerInput', component: IntegerInputComponent },
        { name: 'textInput', component: TextInputComponent },
        { name: 'dateInput', component: DateInputComponent },
        { name: 'selectInput', component: SelectInputComponent },
        { name: 'selectProjectStatusInput', component: SelectProjectStatusInputComponent },
        { name: 'formattableInput', component: FormattableTextareaInputComponent },
      ],
      wrappers: [
        {
          name: 'op-dynamic-field-group-wrapper',
          component: DynamicFieldGroupWrapperComponent,
        },
        {
          name: 'op-dynamic-field-wrapper',
          component: DynamicFieldWrapperComponent,
        },
      ]
    }),
    HttpClientModule,
    OpenprojectCommonModule,

    // Input dependencies
    DatePickerModule,
    NgSelectModule,
    NgOptionHighlightModule,
    FormattableEditFieldModule,
    OpenprojectEditorModule,
  ],
  declarations: [
    DynamicFieldGroupWrapperComponent,
    DynamicFormComponent,
    // Input Types
    BooleanInputComponent,
    IntegerInputComponent,
    TextInputComponent,
    DateInputComponent,
    DatePickerAdapterComponent,
    SelectInputComponent,
    SelectProjectStatusInputComponent,
    FormattableTextareaInputComponent,
    FormattableControlComponent,
    DynamicFieldWrapperComponent,
  ],
  providers: [
    { provide: HTTP_INTERCEPTORS, useClass: OpenProjectHeaderInterceptor, multi: true },
  ],
  exports: [
    DynamicFormComponent,
  ]
})
export class DynamicFormsModule {}
