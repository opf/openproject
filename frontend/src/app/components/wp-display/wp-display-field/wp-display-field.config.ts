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

import {WorkPackageDisplayFieldService} from './wp-display-field.service';
import {TextDisplayField} from '../field-types/wp-display-text-field.module';
import {ResourceDisplayField} from '../field-types/wp-display-resource-field.module';
import {ResourcesDisplayField} from '../field-types/wp-display-resources-field.module';
import {FormattableDisplayField} from '../field-types/wp-display-formattable-field.module';
import {DurationDisplayField} from '../field-types/wp-display-duration-field.module';
import {DateDisplayField} from '../field-types/wp-display-date-field.module';
import {DateTimeDisplayField} from '../field-types/wp-display-datetime-field.module';
import {IdDisplayField} from '../field-types/wp-display-id-field.module';
import {BooleanDisplayField} from '../field-types/wp-display-boolean-field.module';
import {ProgressDisplayField} from '../field-types/wp-display-progress-field.module';
import {openprojectModule} from '../../../angular-modules';
import {SpentTimeDisplayField} from '../field-types/wp-display-spent-time-field.module';
import {IntegerDisplayField} from "../field-types/wp-display-integer-field.module";
import {WorkPackageDisplayField} from "../field-types/wp-display-work-package-field.module";
import {FloatDisplayField} from '../field-types/wp-display-float-field.module';

openprojectModule
  .run((wpDisplayField:WorkPackageDisplayFieldService) => {
    wpDisplayField.defaultType = 'text';
    wpDisplayField
      .addFieldType(TextDisplayField, 'text', ['String'])
      .addFieldType(FloatDisplayField, 'float', ['Float'])
      .addFieldType(IntegerDisplayField, 'integer', ['Integer'])
      .addFieldType(ResourceDisplayField, 'resource', ['User',
                                                       'Project',
                                                       'Type',
                                                       'Status',
                                                       'Priority',
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
  });
