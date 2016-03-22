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
import {Field} from "./wp-edit-field.module";
import {TextField} from "./wp-edit-text-field.module";
import {IntegerField} from "./wp-edit-integer-field.module";
import {DurationField} from "./wp-edit-duration-field.module";
import {SelectField} from "./wp-edit-select-field.module";
import {FloatField} from "./wp-edit-float-field.module";
import {BooleanField} from "./wp-edit-boolean-field.module";
import {DateField} from "./wp-edit-date-field.module";

//TODO: Implement
class DateRangeField extends Field {}

//TODO: Implement
class TextareaField extends Field {}

//TODO: See file wp-field.service.js:getInplaceEditStrategy for more eventual classes

angular
  .module('openproject')
  .run((wpEditField:WorkPackageEditFieldService) => {
    wpEditField.defaultType = 'text';
    wpEditField
      .addFieldType(TextField, 'text', ['String'])
      .addFieldType(IntegerField, 'integer', ['Integer'])
      .addFieldType(DurationField, 'duration', ['Duration'])
      .addFieldType(SelectField, 'select', ['Priority',
                                            'Status',
                                            'Type',
                                            'User',
                                            'Version',
                                            'Category',
                                            'StringObject',
                                            'Project'])
      .addFieldType(FloatField, 'float', ['Float'])
      .addFieldType(IntegerField, 'integer', ['Integer'])
      .addFieldType(BooleanField, 'boolean', ['Boolean'])
      .addFieldType(DateField, 'date', ['Date']);
  });
