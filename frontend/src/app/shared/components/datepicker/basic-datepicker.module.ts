import { Injector, NgModule, inject } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

import { XIconComponent } from '@openproject/octicons-angular';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpBasicRangeDatePickerComponent } from './basic-range-date-picker/basic-range-date-picker.component';
import { OpBasicSingleDatePickerComponent } from './basic-single-date-picker/basic-single-date-picker.component';
import { OpBasicSingleDateTimePickerComponent } from './basic-single-datetime-picker/basic-single-datetime-picker.component';

@NgModule({
  imports: [
    FormsModule,
    ReactiveFormsModule,
    CommonModule,
    XIconComponent,
  ],

  providers: [
    I18nService,
  ],

  declarations: [
    OpBasicRangeDatePickerComponent,
    OpBasicSingleDatePickerComponent,
    OpBasicSingleDateTimePickerComponent,
  ],

  exports: [
    OpBasicRangeDatePickerComponent,
    OpBasicSingleDatePickerComponent,
    OpBasicSingleDateTimePickerComponent,
  ],
})
export class OpBasicDatePickerModule {
  readonly injector = inject(Injector);
}
