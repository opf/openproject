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

import {DisplayField} from "../wp-display-field/wp-display-field.module";

export class ResourcesDisplayField extends DisplayField {
  public template: string = '/components/wp-display/field-types/wp-display-resources-field.directive.html';

  public isEmpty():boolean {
    return _.isEmpty(this.value);
  }

  public get value() {
    if (this.schema) {
      var cf = this.resource[this.name];

      if (cf.elements) {
        return cf.elements.map((e:any) => e.name);
      } else if (cf.map) {
        return cf.map((e:any) => e.name);
      } else if (cf.name) {
        return [cf.name];
      } else {
        return ["error: " + JSON.stringify(cf)];
      }
    } else {
      return null;
    }
  }

  public get valueAbridged() {
    let valueForDisplay = _.take(this.value, 2).join(', ');

    if (this.value.length > 2) {
      valueForDisplay += ', ...';
    }

    return valueForDisplay;
  }
}
