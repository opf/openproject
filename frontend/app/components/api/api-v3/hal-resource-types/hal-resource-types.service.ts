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

import {opApiModule} from '../../../../angular-modules';
import {HalResourceTypesStorageService} from '../hal-resource-types-storage/hal-resource-types-storage.service';

export class HalResourceTypesService {
  constructor(protected $injector,
              protected halResourceTypesStorage:HalResourceTypesStorageService,
              HalResource) {
    halResourceTypesStorage.defaultClass = HalResource;
  }

  public setResourceTypeConfig(config) {
    const types = Object.keys(config).map(typeName => {
      const value = config[typeName];
      const result = {
        typeName: typeName,
        className: value.className || this.getClassName(this.halResourceTypesStorage.defaultClass),
        attrTypes: value.attrTypes || {}
      };

      if (angular.isString(value)) {
        result.className = value;
      }

      if (!value.className && angular.isObject(value)) {
        result.attrTypes = value;
      }

      return result;
    });

    types.forEach(typeConfig => {
      this.halResourceTypesStorage
        .setResourceType(typeConfig.typeName, this.$injector.get(typeConfig.className));
    });

    types
      .forEach(typeConfig => {
        this.halResourceTypesStorage.setResourceTypeAttributes(typeConfig.typeName, typeConfig.attrTypes);
      });
  }

  /**
   * IE11 has no support for <Function>.name, thus polyfill the actual class name
   * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/name
   * @param cls
   */
  protected getClassName(cls:Function) {
    if (cls.hasOwnProperty('name')) {
      return cls.name;
    }

    return cls.toString().match(/^function\s*([^\s(]+)/)[1];
  }
}

opApiModule.service('halResourceTypes', HalResourceTypesService);
