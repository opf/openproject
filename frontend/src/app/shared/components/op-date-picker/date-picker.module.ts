import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpDatePickerComponent } from 'core-app/shared/components/op-date-picker/op-date-picker.component';

@NgModule({
  declarations: [
    OpDatePickerComponent,
  ],
  imports: [
    CommonModule,
  ],
  exports: [
    OpDatePickerComponent,
  ],
})
export class DatePickerModule { }
