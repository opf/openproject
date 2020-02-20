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

import {DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {TextDisplayField} from "core-app/modules/fields/display/field-types/text-display-field.module";
import {FloatDisplayField} from "core-app/modules/fields/display/field-types/float-display-field.module";
import {IntegerDisplayField} from "core-app/modules/fields/display/field-types/integer-display-field.module";
import {ResourceDisplayField} from "core-app/modules/fields/display/field-types/resource-display-field.module";
import {ResourcesDisplayField} from "core-app/modules/fields/display/field-types/resources-display-field.module";
import {FormattableDisplayField} from "core-app/modules/fields/display/field-types/formattable-display-field.module";
import {DurationDisplayField} from "core-app/modules/fields/display/field-types/duration-display-field.module";
import {DateDisplayField} from "core-app/modules/fields/display/field-types/date-display-field.module";
import {DateTimeDisplayField} from "core-app/modules/fields/display/field-types/datetime-display-field.module";
import {BooleanDisplayField} from "core-app/modules/fields/display/field-types/boolean-display-field.module";
import {ProgressDisplayField} from "core-app/modules/fields/display/field-types/progress-display-field.module";
import {WorkPackageDisplayField} from "core-app/modules/fields/display/field-types/work-package-display-field.module";
import {WorkPackageSpentTimeDisplayField} from "core-app/modules/fields/display/field-types/wp-spent-time-display-field.module";
import {IdDisplayField} from "core-app/modules/fields/display/field-types/id-display-field.module";
import {HighlightedResourceDisplayField} from "core-app/modules/fields/display/field-types/highlighted-resource-display-field.module";
import {TypeDisplayField} from "core-app/modules/fields/display/field-types/type-display-field.module";
import {UserDisplayField} from "core-app/modules/fields/display/field-types/user-display-field.module";
import {MultipleUserFieldModule} from "core-app/modules/fields/display/field-types/multiple-user-display-field.module";
import {WorkPackageIdDisplayField} from "core-app/modules/fields/display/field-types/wp-id-display-field.module";
import {ProjectStatusDisplayField} from "core-app/modules/fields/display/field-types/project-status-display-field.module";
import {PlainFormattableDisplayField} from "core-app/modules/fields/display/field-types/plain-formattable-display-field.module";
import {LinkedWorkPackageDisplayField} from "core-app/modules/fields/display/field-types/linked-work-package-display-field.module";

export function initializeCoreDisplayFields(displayFieldService:DisplayFieldService) {
  return () => {
    displayFieldService.defaultFieldType = 'text';
    displayFieldService
      .addFieldType(TextDisplayField, 'text', ['String'])
      .addFieldType(FloatDisplayField, 'float', ['Float'])
      .addFieldType(IntegerDisplayField, 'integer', ['Integer'])
      .addFieldType(HighlightedResourceDisplayField, 'highlight', [
        'Status',
        'Priority'
      ])
      .addFieldType(TypeDisplayField, 'type', ['Type'])
      .addFieldType(ResourceDisplayField, 'resource', [
        'Project',
        'TimeEntriesActivity',
        'Version',
        'Category',
        'CustomOption'])
      .addFieldType(ResourcesDisplayField, 'resources', ['[]CustomOption'])
      .addFieldType(MultipleUserFieldModule, 'users', ['[]User'])
      .addFieldType(FormattableDisplayField, 'formattable', ['Formattable'])
      .addFieldType(DurationDisplayField, 'duration', ['Duration'])
      .addFieldType(DateDisplayField, 'date', ['Date'])
      .addFieldType(DateTimeDisplayField, 'datetime', ['DateTime'])
      .addFieldType(BooleanDisplayField, 'boolean', ['Boolean'])
      .addFieldType(ProgressDisplayField, 'progress', ['percentageDone'])
      .addFieldType(LinkedWorkPackageDisplayField, 'work_package', ['WorkPackage'])
      .addFieldType(IdDisplayField, 'id', ['id'])
      .addFieldType(ProjectStatusDisplayField, 'project_status', ['ProjectStatus'])
      .addFieldType(UserDisplayField, 'user', ['User']);

    displayFieldService
        .addSpecificFieldType('WorkPackage', WorkPackageIdDisplayField, 'id', ['id'])
        .addSpecificFieldType('WorkPackage', WorkPackageSpentTimeDisplayField, 'spentTime', ['spentTime'])
        .addSpecificFieldType('TimeEntry', PlainFormattableDisplayField, 'comment', ['comment'])
        .addSpecificFieldType('TimeEntry', WorkPackageDisplayField, 'work_package', ['workPackage']);
  };
}
