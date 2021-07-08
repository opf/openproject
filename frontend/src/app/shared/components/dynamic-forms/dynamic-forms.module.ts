import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TextInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/text-input/text-input.component';
import { HTTP_INTERCEPTORS, HttpClientModule } from '@angular/common/http';
import { IntegerInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/integer-input/integer-input.component';
import { FormlyModule } from '@ngx-formly/core';
import { SelectInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/select-input/select-input.component';
import { SelectProjectStatusInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/select-project-status-input/select-project-status-input.component';
import { NgOptionHighlightModule } from '@ng-select/ng-option-highlight';
import { NgSelectModule } from '@ng-select/ng-select';
import { DatePickerControlModule } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/date-input/components/date-picker-control/date-picker-control.module';
import { BooleanInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/boolean-input/boolean-input.component';
import { DynamicFormComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-form/dynamic-form.component';
import { FormattableTextareaInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/formattable-textarea-input/formattable-textarea-input.component';
import { DynamicFieldWrapperComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-field-wrapper/dynamic-field-wrapper.component';
import { InviteUserButtonModule } from 'core-app/features/invite-user-modal/button/invite-user-button.module';
import { DateInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/date-input/date-input.component';
import { DynamicFieldGroupWrapperComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-field-group-wrapper/dynamic-field-group-wrapper.component';
import { OpenProjectHeaderInterceptor } from 'core-app/features/hal/http/openproject-header-interceptor';
import { ReactiveFormsModule } from '@angular/forms';
import { FormattableControlModule } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/formattable-textarea-input/components/formattable-control/formattable-control.module';
import { OPSharedModule } from 'core-app/shared/shared.module';

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
      ],
    }),
    HttpClientModule,
    OPSharedModule,

    // Input dependencies
    NgSelectModule,
    NgOptionHighlightModule,
    InviteUserButtonModule,
    DatePickerControlModule,
    FormattableControlModule,
  ],
  declarations: [
    DynamicFormComponent,
    DynamicFieldGroupWrapperComponent,
    DynamicFieldWrapperComponent,
    // Input Types
    BooleanInputComponent,
    IntegerInputComponent,
    TextInputComponent,
    SelectInputComponent,
    SelectProjectStatusInputComponent,
    DateInputComponent,
    FormattableTextareaInputComponent,
  ],
  providers: [
    { provide: HTTP_INTERCEPTORS, useClass: OpenProjectHeaderInterceptor, multi: true },
  ],
  exports: [
    DynamicFormComponent,
  ],
})
export class DynamicFormsModule {}
