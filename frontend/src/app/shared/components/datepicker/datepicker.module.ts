import { NgModule } from '@angular/core';
import { A11yModule } from '@angular/cdk/a11y';
import {
  FormsModule,
  ReactiveFormsModule,
} from '@angular/forms';
import { CommonModule } from '@angular/common';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalSingleDatePickerComponent } from './modal-single-date-picker/modal-single-date-picker.component';
import { OpBasicDatePickerModule } from './basic-datepicker.module';
import { OpSpotModule } from 'core-app/spot/spot.module';
import { OpenprojectModalModule } from '../modal/modal.module';
import { OpDatePickerSheetComponent } from 'core-app/shared/components/datepicker/sheet/date-picker-sheet.component';
import { OpenprojectContentLoaderModule } from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { OpWpDatePickerInstanceComponent } from 'core-app/shared/components/datepicker/wp-date-picker-modal/wp-date-picker-instance.component';

@NgModule({
  imports: [
    FormsModule,
    ReactiveFormsModule,
    CommonModule,
    A11yModule,
    OpSpotModule,
    OpBasicDatePickerModule,
    OpenprojectModalModule,
    OpenprojectContentLoaderModule,
  ],

  providers: [
    I18nService,
  ],

  declarations: [
    OpModalSingleDatePickerComponent,
    OpDatePickerSheetComponent,
    OpWpDatePickerInstanceComponent,
  ],

  exports: [
    OpModalSingleDatePickerComponent,
    OpBasicDatePickerModule,
    OpDatePickerSheetComponent,
    OpWpDatePickerInstanceComponent,
  ],
})
export class OpDatePickerModule { }
