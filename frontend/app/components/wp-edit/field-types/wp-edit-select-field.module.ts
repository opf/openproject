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

import {Field} from "../wp-edit-field/wp-edit-field.module";

export class SelectField extends Field {
  public options:any[];
  public placeholder:string = '-';
  public template:string = '/components/wp-edit/field-types/wp-edit-select-field.directive.html'
  public text;

  constructor(workPackage, fieldName, schema) {
    super(workPackage, fieldName, schema);

    const I18n:any = this.$injector.get('I18n');
    this.text = {
      requiredPlaceholder: I18n.t('js.placeholders.selection'),
      placeholder: I18n.t('js.placeholders.default')
    };

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
        name: this.text.placeholder,
      });
    }
  }
}
