//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
