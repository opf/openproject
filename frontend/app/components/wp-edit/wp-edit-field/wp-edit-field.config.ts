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

import {WorkPackageEditFieldService} from "./wp-edit-field.service";
import {EditField} from "./wp-edit-field.module";
import {TextEditField} from "../field-types/wp-edit-text-field.module";
import {IntegerEditField} from "../field-types/wp-edit-integer-field.module";
import {DurationEditField} from "../field-types/wp-edit-duration-field.module";
import {SelectEditField} from "../field-types/wp-edit-select-field.module";
import {MultiSelectEditField} from "../field-types/wp-edit-multi-select-field.module";
import {FloatEditField} from "../field-types/wp-edit-float-field.module";
import {BooleanEditField} from "../field-types/wp-edit-boolean-field.module";
import {DateEditField} from "../field-types/wp-edit-date-field.module";
import {WikiTextareaEditField} from "../field-types/wp-edit-wiki-textarea-field.module";
import {WorkPackageEditField} from './../field-types/wp-edit-work-package-field.module';
import {openprojectModule} from "../../../angular-modules";

openprojectModule
  .run((wpEditField:WorkPackageEditFieldService) => {
    wpEditField.defaultType = 'text';
    wpEditField
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
      .addFieldType(IntegerEditField, 'integer', ['Integer'])
      .addFieldType(BooleanEditField, 'boolean', ['Boolean'])
      .addFieldType(DateEditField, 'date', ['Date'])
      .addFieldType(WikiTextareaEditField, 'wiki-textarea', ['Formattable']);
  });
