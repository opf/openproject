import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule, ReactiveFormsModule } from "@angular/forms";
import { FormlyModule } from "@ngx-formly/core";
import { HTTP_INTERCEPTORS, HttpClientModule } from "@angular/common/http";
import { NgSelectModule } from "@ng-select/ng-select";
import { DynamicFieldGroupWrapperComponent } from "./components/dynamic-field-group-wrapper/dynamic-field-group-wrapper.component";
import { DynamicFormComponent } from "./components/dynamic-form/dynamic-form.component";
import { OpenProjectHeaderInterceptor } from "core-app/modules/hal/http/openproject-header-interceptor";
import { TextInputComponent } from './components/dynamic-inputs/text-input/text-input.component';
import { IntegerInputComponent } from './components/dynamic-inputs/integer-input/integer-input.component';
import { SelectInputComponent } from './components/dynamic-inputs/select-input/select-input.component';
import { NgOptionHighlightModule } from "@ng-select/ng-option-highlight";
import { BooleanInputComponent } from './components/dynamic-inputs/boolean-input/boolean-input.component';
import { DateInputComponent } from './components/dynamic-inputs/date-input/date-input.component';
import { DatePickerAdapterComponent } from './components/dynamic-inputs/date-input/components/date-picker-adapter/date-picker-adapter.component';
import { FormattableTextareaInputComponent } from './components/dynamic-inputs/formattable-textarea-input/formattable-textarea-input.component';
import { OpenprojectEditorModule } from "core-app/modules/editor/openproject-editor.module";
import { OpenprojectFieldsModule } from "core-app/modules/fields/openproject-fields.module";
import { FormattableControlComponent } from './components/dynamic-inputs/formattable-textarea-input/components/formattable-control/formattable-control.component';
import { OpenprojectCommonModule } from "core-app/modules/common/openproject-common.module";

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    FormlyModule.forRoot({
      types: [
        { name: 'textInput', component: TextInputComponent },
        { name: 'integerInput', component: IntegerInputComponent },
        { name: 'selectInput', component: SelectInputComponent },
        { name: 'booleanInput', component: BooleanInputComponent },
        { name: 'dateInput', component: DateInputComponent },
        { name: 'formattableInput', component: FormattableTextareaInputComponent },
      ],
      wrappers: [
        {
          name: "op-dynamic-field-group-wrapper",
          component: DynamicFieldGroupWrapperComponent,
        },
      ]
    }),
    HttpClientModule,
    NgSelectModule,
    NgOptionHighlightModule,
    OpenprojectEditorModule,
    // TODO: Import only necessary fields (EditFieldControlsComponent)
    OpenprojectFieldsModule,
    OpenprojectCommonModule,
  ],
  declarations: [
    DynamicFieldGroupWrapperComponent,
    DynamicFormComponent,
    // Input Types
    TextInputComponent,
    IntegerInputComponent,
    SelectInputComponent,
    BooleanInputComponent,
    DateInputComponent,
    DatePickerAdapterComponent,
    FormattableTextareaInputComponent,
    FormattableControlComponent,
  ],
  providers: [
    { provide: HTTP_INTERCEPTORS, useClass: OpenProjectHeaderInterceptor, multi: true },
  ],
  exports: [
    DynamicFormComponent,
  ]
})
export class DynamicFormsModule {}
