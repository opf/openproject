import { Injector, NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpBasicRangeDatePickerComponent } from './basic-range-date-picker/basic-range-date-picker.component';
import { OpBasicSingleDatePickerComponent } from './basic-single-date-picker/basic-single-date-picker.component';

@NgModule({
  imports: [
    FormsModule,
    ReactiveFormsModule,
    CommonModule,
  ],

  providers: [
    I18nService,
  ],

  declarations: [
    OpBasicRangeDatePickerComponent,
    OpBasicSingleDatePickerComponent,
  ],

  exports: [
    OpBasicRangeDatePickerComponent,
    OpBasicSingleDatePickerComponent,
  ],
})
export class OpBasicDatePickerModule {
  constructor(readonly injector:Injector) {
  }
}
