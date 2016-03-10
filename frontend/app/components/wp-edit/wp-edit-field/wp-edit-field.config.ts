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

import {Field} from "./wp-edit-field.module";
import {WorkPackageEditFieldService} from "./wp-edit-field.service";


class TextField extends Field {
}

class SelectField extends Field {
  public options:any[];
  public placeholder:string = '-';

  constructor(workPackage, fieldName, schema) {
    super(workPackage, fieldName, schema);

    if (angular.isArray(this.schema.allowedValues)) {
      this.options = angular.copy(this.schema.allowedValues);
      this.addEmptyOption();
    } else {
      this.schema.allowedValues.$load().then((values) => {
        this.options = angular.copy(values.elements);
        this.addEmptyOption();
      });
    }
  }

  private addEmptyOption() {
    if (!this.schema.required) {
      this.options.unshift({
        href: "null",
        name: this.placeholder,
      });
    }
  }
}

//TODO: Implement
class DateField extends Field {}

//TODO: Implement
class DateRangeField extends Field {}

//TODO: Implement
class IntegerField extends Field {}

//TODO: Implement
class FloatField extends Field {}

//TODO: Implement
class BooleanField extends Field {}

//TODO: Implement
class DurationField extends Field {}

//TODO: Implement
class TextareaField extends Field {}

//TODO: See file wp-field.service.js:getInplaceEditStrategy for more eventual classes

angular
  .module('openproject')
  .run((wpEditField:WorkPackageEditFieldService) => {
    wpEditField.defaultType = 'text';
    wpEditField
      .addFieldType(TextField, 'text', ['String'])
      .addFieldType(SelectField, 'select', ['Priority',
                                            'Status',
                                            'Type',
                                            'User',
                                            'Version',
                                            'Category']);
  });
