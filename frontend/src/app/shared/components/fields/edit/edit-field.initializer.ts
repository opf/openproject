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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { EditFieldService } from 'core-app/shared/components/fields/edit/edit-field.service';
import {
  TextEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/text-edit-field/text-edit-field.component';
import {
  IntegerEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/integer-edit-field/integer-edit-field.component';
import {
  SelectEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/select-edit-field/select-edit-field.component';
import {
  MultiSelectEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/multi-select-edit-field.component';
import { FloatEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/float-edit-field.component';
import {
  BooleanEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/boolean-edit-field/boolean-edit-field.component';
import {
  WorkPackageEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/work-package-edit-field.component';
import {
  DateEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/date-edit-field/date-edit-field.component';
import {
  FormattableEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/formattable-edit-field/formattable-edit-field.component';
import {
  SelectAutocompleterRegisterService,
} from 'core-app/shared/components/fields/edit/field-types/select-edit-field/select-autocompleter-register.service';
import {
  ProjectStatusEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/project-status-edit-field.component';
import {
  PlainFormattableEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/plain-formattable-edit-field.component';
import {
  TimeEntryWorkPackageEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/te-work-package-edit-field.component';
import {
  CombinedDateEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/combined-date-edit-field.component';
import {
  VersionAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/version-autocompleter/version-autocompleter.component';
import {
  WorkPackageAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/work-package-autocompleter/wp-autocompleter.component';
import {
  WorkPackageCommentFieldComponent,
} from 'core-app/features/work-packages/components/work-package-comment/wp-comment-field.component';
import { ProjectEditFieldComponent } from './field-types/project-edit-field.component';
import {
  HoursDurationEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/hours-duration-edit-field.component';
import { UserEditFieldComponent } from './field-types/user-edit-field.component';
import {
  DaysDurationEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/days-duration-edit-field.component';
import {
  ProgressPopoverEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/progress-popover-edit-field.component';

export function initializeCoreEditFields(editFieldService:EditFieldService, selectAutocompleterRegisterService:SelectAutocompleterRegisterService) {
  return ():void => {
    editFieldService.defaultFieldType = 'text';
    editFieldService
      .addFieldType(TextEditFieldComponent, 'text', ['String'])
      .addFieldType(IntegerEditFieldComponent, 'integer', ['Integer'])
      .addFieldType(ProgressPopoverEditFieldComponent, 'progress', ['Progress'])
      .addFieldType(ProjectEditFieldComponent, 'project', ['Project'])
      .addFieldType(UserEditFieldComponent, 'user', ['User'])
      .addFieldType(SelectEditFieldComponent, 'select', [
        'Priority',
        'Status',
        'Type',
        'Version',
        'TimeEntriesActivity',
        'Category',
        'CustomOption',
      ])
      .addFieldType(MultiSelectEditFieldComponent, 'multi-select', [
        '[]CustomOption',
        '[]User',
        '[]Version',
      ])
      .addFieldType(FloatEditFieldComponent, 'float', ['Float'])
      .addFieldType(WorkPackageEditFieldComponent, 'workPackage', ['WorkPackage'])
      .addFieldType(BooleanEditFieldComponent, 'boolean', ['Boolean'])
      .addFieldType(DateEditFieldComponent, 'date', ['Date'])
      .addFieldType(FormattableEditFieldComponent, 'wiki-textarea', ['Formattable'])
      .addFieldType(WorkPackageCommentFieldComponent, '_comment', ['comment']);

    editFieldService
      .addSpecificFieldType(
        'WorkPackage',
        CombinedDateEditFieldComponent,
        'date',
        ['combinedDate', 'startDate', 'dueDate', 'date'],
      )
      .addSpecificFieldType(
        'WorkPackage',
        DaysDurationEditFieldComponent,
        'duration',
        ['duration'],
      )
      .addSpecificFieldType(
        'WorkPackage',
        ProgressPopoverEditFieldComponent,
        'progress',
        ['estimatedTime', 'remainingTime', 'percentageDone'],
      )
      .addSpecificFieldType('Project', ProjectStatusEditFieldComponent, 'status', ['status'])
      .addSpecificFieldType('TimeEntry', PlainFormattableEditFieldComponent, 'comment', ['comment'])
      .addSpecificFieldType('TimeEntry', TimeEntryWorkPackageEditFieldComponent, 'workPackage', ['WorkPackage'])
      .addSpecificFieldType('TimeEntry', HoursDurationEditFieldComponent, 'hours', ['hours']);

    selectAutocompleterRegisterService.register(VersionAutocompleterComponent, 'Version');
    selectAutocompleterRegisterService.register(WorkPackageAutocompleterComponent, 'WorkPackage');
  };
}
