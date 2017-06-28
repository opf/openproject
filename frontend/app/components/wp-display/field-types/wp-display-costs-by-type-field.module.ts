//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
//++

import {DisplayField} from 'core-components/wp-display/wp-display-field/wp-display-field.module';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {HalResource} from 'core-components/api/api-v3/hal-resources/hal-resource.service';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';


interface ICostsByType {
  $source: {
    _links: {
      costType: {
        title: string;
      }
    }
  };
  spentUnits: number;
}

export class CostsByTypeDisplayField extends DisplayField {

  public wpCacheService:WorkPackageCacheService;

  constructor(public resource:HalResource,
              public name:string,
              public schema:op.FieldSchema) {
    super(resource, name, schema);

    this.wpCacheService = <WorkPackageCacheService>this.$injector.get('wpCacheService');

    this.loadIfNecessary();
  }

  protected loadIfNecessary() {
    if (this.value && this.value.$loaded === false) {
      this.value.$load().then(() => {

        if (this.resource.$source._type === 'WorkPackage') {
          this.wpCacheService.updateWorkPackage(<WorkPackageResourceInterface> this.resource);
        }
      });
    }
  }

  public get valueString() {
    return  _.map(this.value.elements, (val: ICostsByType) => {
      return val.spentUnits + ' ' + val.$source._links.costType.title;
    }).join(', ');
  };

  public isEmpty(): boolean {
    return !this.value ||
           !this.value.elements ||
           this.value.elements.length === 0;
  }
}
