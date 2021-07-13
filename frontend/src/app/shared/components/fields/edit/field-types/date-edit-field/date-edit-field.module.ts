import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DateEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/date-edit-field/date-edit-field.component';
import { DatePickerModule } from 'core-app/shared/components/op-date-picker/date-picker.module';

@NgModule({
  declarations: [
    DateEditFieldComponent,
  ],
  imports: [
    CommonModule,
    DatePickerModule,

  ],
  exports: [
    DateEditFieldComponent,
  ],
})
export class DateEditFieldModule { }
