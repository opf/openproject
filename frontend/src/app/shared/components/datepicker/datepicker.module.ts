import { NgModule } from '@angular/core';
import { A11yModule } from '@angular/cdk/a11y';
import {
  FormsModule,
  ReactiveFormsModule,
} from '@angular/forms';
import { CommonModule } from '@angular/common';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalSingleDatePickerComponent } from './modal-single-date-picker/modal-single-date-picker.component';
import { OpWpMultiDateFormComponent } from './wp-multi-date-form/wp-multi-date-form.component';
import { OpWpSingleDateFormComponent } from './wp-single-date-form/wp-single-date-form.component';
import { OpDatePickerBannerComponent } from './banner/datepicker-banner.component';
import { OpDatePickerSchedulingToggleComponent } from './scheduling-mode/datepicker-scheduling-toggle.component';
import { OpDatePickerWorkingDaysToggleComponent } from './toggle/datepicker-working-days-toggle.component';
import { OpBasicDatePickerModule } from './basic-datepicker.module';
import { OpSpotModule } from 'core-app/spot/spot.module';
import { OpenprojectModalModule } from '../modal/modal.module';
import { OpDatePickerSheetComponent } from 'core-app/shared/components/datepicker/sheet/date-picker-sheet.component';

@NgModule({
  imports: [
    FormsModule,
    ReactiveFormsModule,
    CommonModule,
    A11yModule,
    OpSpotModule,
    OpBasicDatePickerModule,
    OpenprojectModalModule,
  ],

  providers: [
    I18nService,
  ],

  declarations: [
    OpDatePickerBannerComponent,
    OpDatePickerSchedulingToggleComponent,
    OpDatePickerWorkingDaysToggleComponent,

    OpModalSingleDatePickerComponent,
    OpWpMultiDateFormComponent,
    OpWpSingleDateFormComponent,
    OpDatePickerSheetComponent,
  ],

  exports: [
    OpModalSingleDatePickerComponent,
    OpWpMultiDateFormComponent,
    OpWpSingleDateFormComponent,
    OpBasicDatePickerModule,
    OpDatePickerSheetComponent,
  ],
})
export class OpDatePickerModule { }
