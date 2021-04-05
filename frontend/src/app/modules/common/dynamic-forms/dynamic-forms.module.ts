import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { OpSelectComponent } from "./components/op-select/op-select.component";
import { FormsModule, ReactiveFormsModule } from "@angular/forms";
import { FormlyModule } from "@ngx-formly/core";
import { HTTP_INTERCEPTORS, HttpClientModule } from "@angular/common/http";
import { NgSelectModule } from "@ng-select/ng-select";
import { OpFieldGroupWrapperComponent } from "./components/op-field-group-wrapper/op-field-group-wrapper.component";
import { OpDynamicFormComponent } from "./components/op-dynamic-form/op-dynamic-form.component";
import { OpFieldWrapperComponent } from "./components/op-field-wrapper/op-field-wrapper.component";
import { OpenProjectHeaderInterceptor } from "core-app/modules/hal/http/openproject-header-interceptor";
import { TextInputComponent } from './components/inputs/text-input/text-input.component';
import { IntegerInputComponent } from './components/inputs/integer-input/integer-input.component';
import { SelectInputComponent } from './components/inputs/select-input/select-input.component';
import { NgOptionHighlightModule } from "@ng-select/ng-option-highlight";
import { BooleanInputComponent } from './components/inputs/boolean-input/boolean-input.component';
import { DateInputComponent } from './components/inputs/date-input/date-input.component';
import { DatePickerAdapterComponent } from './components/inputs/date-input/components/date-picker-adapter/date-picker-adapter.component';
import { FormattableTextareaInputComponent } from './components/inputs/formattable-textarea-input/formattable-textarea-input.component';
import { OpenprojectEditorModule } from "core-app/modules/editor/openproject-editor.module";
import { OpenprojectFieldsModule } from "core-app/modules/fields/openproject-fields.module";
import { FormattableControlComponent } from './components/inputs/formattable-textarea-input/components/formattable-control/formattable-control.component';
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
    OpSelectComponent,
    OpFieldGroupWrapperComponent,
    OpDynamicFormComponent,
    OpFieldWrapperComponent,
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
    OpDynamicFormComponent,
  ]
})
export class DynamicFormsModule {}
