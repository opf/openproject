import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DatePickerControlComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/date-input/components/date-picker-control/date-picker-control.component";
import { DatePickerModule } from "core-app/modules/common/op-date-picker/date-picker.module";



@NgModule({
  declarations: [
    DatePickerControlComponent,
  ],
  imports: [
    CommonModule,
    DatePickerModule,
  ],
  exports: [
    DatePickerControlComponent,
  ]
})
export class DatePickerControlModule { }
