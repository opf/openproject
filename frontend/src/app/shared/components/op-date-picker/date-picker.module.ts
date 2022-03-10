import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpRangeDatePickerComponent } from 'core-app/shared/components/op-date-picker/op-range-date-picker/op-range-date-picker.component';
import { OpSingleDatePickerComponent } from 'core-app/shared/components/op-date-picker/op-single-date-picker/op-single-date-picker.component';

@NgModule({
  declarations: [
    OpSingleDatePickerComponent,
    OpRangeDatePickerComponent,
  ],
  imports: [
    CommonModule,
  ],
  exports: [
    OpSingleDatePickerComponent,
    OpRangeDatePickerComponent,
  ],
})
export class DatePickerModule { }
