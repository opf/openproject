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

import {EditFieldService} from "core-app/modules/fields/edit/edit-field.service";
import {TextEditField} from "core-app/modules/fields/edit/field-types/text-edit-field";
import {IntegerEditField} from "core-app/modules/fields/edit/field-types/integer-edit-field";
import {DurationEditField} from "core-app/modules/fields/edit/field-types/duration-edit-field";
import {SelectEditField} from "core-app/modules/fields/edit/field-types/select-edit-field";
import {MultiSelectEditField} from "core-app/modules/fields/edit/field-types/multi-select-edit-field";
import {FloatEditField} from "core-app/modules/fields/edit/field-types/float-edit-field";
import {WorkPackageEditField} from "core-app/modules/fields/edit/field-types/work-package-edit-field.module";
import {BooleanEditField} from "core-app/modules/fields/edit/field-types/boolean-edit-field";
import {DateEditField} from "core-app/modules/fields/edit/field-types/date-edit-field";
import {FormattableEditField} from "core-app/modules/fields/edit/field-types/formattable-edit-field";


export function initializeCoreEditFields(editFieldService:EditFieldService) {
  return () => {
    editFieldService.defaultFieldType = 'text';
    editFieldService
      .addFieldType(TextEditField, 'text', ['String'])
      .addFieldType(IntegerEditField, 'integer', ['Integer'])
      .addFieldType(DurationEditField, 'duration', ['Duration'])
      .addFieldType(SelectEditField, 'select', ['Priority',
        'Status',
        'Type',
        'User',
        'Version',
        'Category',
        'CustomOption',
        'Project'])
      .addFieldType(MultiSelectEditField, 'multi-select', [
        '[]CustomOption',
        '[]User'
      ])
      .addFieldType(FloatEditField, 'float', ['Float'])
      .addFieldType(WorkPackageEditField, 'workPackage', ['WorkPackage'])
      .addFieldType(BooleanEditField, 'boolean', ['Boolean'])
      .addFieldType(DateEditField, 'date', ['Date'])
      .addFieldType(FormattableEditField, 'wiki-textarea', ['Formattable']);
  };
}
