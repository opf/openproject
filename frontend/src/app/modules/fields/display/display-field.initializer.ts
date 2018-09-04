// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {TextDisplayField} from "core-app/modules/fields/display/field-types/wp-display-text-field.module";
import {FloatDisplayField} from "core-app/modules/fields/display/field-types/wp-display-float-field.module";
import {IntegerDisplayField} from "core-app/modules/fields/display/field-types/wp-display-integer-field.module";
import {ResourceDisplayField} from "core-app/modules/fields/display/field-types/wp-display-resource-field.module";
import {ResourcesDisplayField} from "core-app/modules/fields/display/field-types/wp-display-resources-field.module";
import {FormattableDisplayField} from "core-app/modules/fields/display/field-types/wp-display-formattable-field.module";
import {DurationDisplayField} from "core-app/modules/fields/display/field-types/wp-display-duration-field.module";
import {DateDisplayField} from "core-app/modules/fields/display/field-types/wp-display-date-field.module";
import {DateTimeDisplayField} from "core-app/modules/fields/display/field-types/wp-display-datetime-field.module";
import {BooleanDisplayField} from "core-app/modules/fields/display/field-types/wp-display-boolean-field.module";
import {ProgressDisplayField} from "core-app/modules/fields/display/field-types/wp-display-progress-field.module";
import {WorkPackageDisplayField} from "core-app/modules/fields/display/field-types/wp-display-work-package-field.module";
import {SpentTimeDisplayField} from "core-app/modules/fields/display/field-types/wp-display-spent-time-field.module";
import {IdDisplayField} from "core-app/modules/fields/display/field-types/wp-display-id-field.module";
import {HighlightedResourceDisplayField} from "core-app/modules/fields/display/field-types/wp-display-highlighted-resource-field.module";

export function initializeCoreDisplayFields(displayFieldService:DisplayFieldService) {
  return () => {
    displayFieldService.defaultFieldType = 'text';
    displayFieldService
      .addFieldType(TextDisplayField, 'text', ['String'])
      .addFieldType(FloatDisplayField, 'float', ['Float'])
      .addFieldType(IntegerDisplayField, 'integer', ['Integer'])
      .addFieldType(HighlightedResourceDisplayField, 'highlight', ['Status', 'Priority'])
      .addFieldType(ResourceDisplayField, 'resource', ['User',
        'Project',
        'Type',
        'Version',
        'Category',
        'CustomOption'])
      .addFieldType(ResourcesDisplayField, 'resources', ['[]CustomOption',
        '[]User'])
      .addFieldType(FormattableDisplayField, 'formattable', ['Formattable'])
      .addFieldType(DurationDisplayField, 'duration', ['Duration'])
      .addFieldType(DateDisplayField, 'date', ['Date'])
      .addFieldType(DateTimeDisplayField, 'datetime', ['DateTime'])
      .addFieldType(BooleanDisplayField, 'boolean', ['Boolean'])
      .addFieldType(ProgressDisplayField, 'progress', ['percentageDone'])
      .addFieldType(WorkPackageDisplayField, 'work_package', ['WorkPackage'])
      .addFieldType(SpentTimeDisplayField, 'spentTime', ['spentTime'])
      .addFieldType(IdDisplayField, 'id', ['id']);
  };
}
