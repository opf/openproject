import { NgModule } from '@angular/core';
import {
  FormsModule,
  ReactiveFormsModule,
} from '@angular/forms';
import { CommonModule } from '@angular/common';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpBasicRangeDatePickerComponent } from './basic-range-date-picker/basic-range-date-picker.component';
import { OpBasicSingleDatePickerComponent } from './basic-single-date-picker/basic-single-date-picker.component';
import { OpModalSingleDatePickerComponent } from './modal-single-date-picker/modal-single-date-picker.component';
import { OpWpMultiDateFormComponent } from './wp-multi-date-form/wp-multi-date-form.component';
import { OpWpSingleDateFormComponent } from './wp-single-date-form/wp-single-date-form.component';
import { OpDatePickerBannerComponent } from './banner/datepicker-banner.component';
import { OpDatePickerSchedulingToggleComponent } from './scheduling-mode/datepicker-scheduling-toggle.component';
import { OpDatePickerWorkingDaysToggleComponent } from './toggle/datepicker-working-days-toggle.component';

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
    OpDatePickerBannerComponent,
    OpDatePickerSchedulingToggleComponent,
    OpDatePickerWorkingDaysToggleComponent,

    OpBasicRangeDatePickerComponent,
    OpBasicSingleDatePickerComponent,
    OpModalSingleDatePickerComponent,
    OpWpMultiDateFormComponent,
    OpWpSingleDateFormComponent,
  ],

  exports: [
    OpBasicRangeDatePickerComponent,
    OpBasicSingleDatePickerComponent,
    OpModalSingleDatePickerComponent,
    OpWpMultiDateFormComponent,
    OpWpSingleDateFormComponent,
  ],
})
export class OpDatePickerModule { }
