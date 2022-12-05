import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DatePickerModule } from 'core-app/shared/components/op-date-picker/date-picker.module';
import { DatePickerControlComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/date-input/components/date-picker-control/date-picker-control.component';
import { OpSpotModule } from 'core-app/spot/spot.module';

@NgModule({
  declarations: [
    DatePickerControlComponent,
  ],
  imports: [
    CommonModule,
    DatePickerModule,
    OpSpotModule,
  ],
  exports: [
    DatePickerControlComponent,
  ],
})
export class DatePickerControlModule { }
