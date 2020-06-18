// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {EditFieldService} from "core-app/modules/fields/edit/edit-field.service";
import {TextEditFieldComponent} from "core-app/modules/fields/edit/field-types/text-edit-field.component";
import {IntegerEditFieldComponent} from "core-app/modules/fields/edit/field-types/integer-edit-field.component";
import {DurationEditFieldComponent} from "core-app/modules/fields/edit/field-types/duration-edit-field.component";
import {SelectEditFieldComponent} from "core-app/modules/fields/edit/field-types/select-edit-field.component";
import {MultiSelectEditFieldComponent} from "core-app/modules/fields/edit/field-types/multi-select-edit-field.component";
import {FloatEditFieldComponent} from "core-app/modules/fields/edit/field-types/float-edit-field.component";
import {BooleanEditFieldComponent} from "core-app/modules/fields/edit/field-types/boolean-edit-field.component";
import {WorkPackageEditFieldComponent} from "core-app/modules/fields/edit/field-types/work-package-edit-field.component";
import {DateEditFieldComponent} from "core-app/modules/fields/edit/field-types/date-edit-field.component";
import {FormattableEditFieldComponent} from "core-app/modules/fields/edit/field-types/formattable-edit-field.component";
import {WorkPackageCommentFieldComponent} from "core-components/work-packages/work-package-comment/wp-comment-field.component";
import {SelectAutocompleterRegisterService} from "core-app/modules/fields/edit/field-types/select-autocompleter-register.service";
import {VersionAutocompleterComponent} from "core-app/modules/common/autocomplete/version-autocompleter.component";
import {ProjectStatusEditFieldComponent} from "core-app/modules/fields/edit/field-types/project-status-edit-field.component";
import {PlainFormattableEditFieldComponent} from "core-app/modules/fields/edit/field-types/plain-formattable-edit-field.component";
import {WorkPackageAutocompleterComponent} from "core-app/modules/common/autocomplete/wp-autocompleter.component";
import {TimeEntryWorkPackageEditFieldComponent} from "core-app/modules/fields/edit/field-types/te-work-package-edit-field.component";
import {CombinedDateEditFieldComponent} from "core-app/modules/fields/edit/field-types/combined-date-edit-field.component";


export function initializeCoreEditFields(editFieldService:EditFieldService, selectAutocompleterRegisterService:SelectAutocompleterRegisterService) {
  return () => {
    editFieldService.defaultFieldType = 'text';
    editFieldService
      .addFieldType(TextEditFieldComponent, 'text', ['String'])
      .addFieldType(IntegerEditFieldComponent, 'integer', ['Integer'])
      .addFieldType(DurationEditFieldComponent, 'duration', ['Duration'])
      .addFieldType(SelectEditFieldComponent, 'select', ['Priority',
        'Status',
        'Type',
        'User',
        'Version',
        'TimeEntriesActivity',
        'Category',
        'CustomOption',
        'Project'])
      .addFieldType(MultiSelectEditFieldComponent, 'multi-select', [
        '[]CustomOption',
        '[]User'
      ])
      .addFieldType(FloatEditFieldComponent, 'float', ['Float'])
      .addFieldType(WorkPackageEditFieldComponent, 'workPackage', ['WorkPackage'])
      .addFieldType(BooleanEditFieldComponent, 'boolean', ['Boolean'])
      .addFieldType(DateEditFieldComponent, 'date', ['Date'])
      .addFieldType(FormattableEditFieldComponent, 'wiki-textarea', ['Formattable'])
      .addFieldType(ProjectStatusEditFieldComponent, 'project_status', ['ProjectStatus'])
      .addFieldType(WorkPackageCommentFieldComponent, '_comment', ['comment']);

    editFieldService
      .addSpecificFieldType('WorkPackage', CombinedDateEditFieldComponent, 'date', ['startDate', 'dueDate', 'date'])
      .addSpecificFieldType('TimeEntry', PlainFormattableEditFieldComponent, 'comment', ['comment'])
      .addSpecificFieldType('TimeEntry', TimeEntryWorkPackageEditFieldComponent, 'workPackage', ['WorkPackage']);

    selectAutocompleterRegisterService.register(VersionAutocompleterComponent, 'Version');
    selectAutocompleterRegisterService.register(WorkPackageAutocompleterComponent, 'WorkPackage');
  };
}
