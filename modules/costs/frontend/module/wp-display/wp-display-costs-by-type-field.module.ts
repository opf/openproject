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


import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {DisplayFieldContext} from 'core-app/modules/fields/display/display-field.service';

interface ICostsByType {
    costObjectId:string;
    costType:{
        name:string;
    };
    staticPath:{
        href:string;
    };
    spentUnits:number;
}

export class CostsByTypeDisplayField extends DisplayField {

    public wpCacheService:any;

    constructor(public resource:any,
                public name:string,
                public schema:any,
                public context:DisplayFieldContext) {
        super(resource, name, schema, context);

        this.wpCacheService = this.$injector.get(WorkPackageCacheService);

        this.loadIfNecessary();
    }

    protected loadIfNecessary() {
        if (this.value && this.value.$loaded === false) {
            this.value.$load().then(() => {

                if (this.resource.$source._type === 'WorkPackage') {
                    this.wpCacheService.updateWorkPackage(this.resource);
                }
            });
        }
    }

    public get title() {
        return '';
    }

    public render(element:HTMLElement, displayText:string):void {
        if (this.isEmpty()) {
            element.textContent = this.placeholder;
            return;
        }

        this.value.elements.forEach((val:ICostsByType, i:number) => {
          if (this.resource.showCosts) {
            this.renderCostAsLink(val, element, i);
          } else {
            this.renderCostAsText(val, element, i);
          }
        });
    }

    public isEmpty():boolean {
        return !this.value ||
            !this.value.elements ||
            this.value.elements.length === 0;
    }


  /**
   * Render link to reporting
   */
  private renderCostAsLink(val:ICostsByType, element:HTMLElement, i:number) {
    const showCosts = this.resource.showCosts;
    const link = document.createElement('a') as HTMLAnchorElement;

    link.href = showCosts.href + '?cost_type_id=' + val.costObjectId;
    link.setAttribute('target', '_blank');
    link.textContent = val.spentUnits + ' ' + val.costType.name;
    element.appendChild(link);

    if (i < this.value.elements.length - 1) {
      const sep = document.createElement('span');
      sep.textContent = ', ';

      element.appendChild(sep);
    }

  }

  /**
   * Render text
   */
  private renderCostAsText(val:ICostsByType, element:HTMLElement, i:number) {
    const span = document.createElement('span');
    span.textContent = val.spentUnits + ' ' + val.costType.name;

    if (i < this.value.elements.length - 1) {
      const sep = document.createElement('span');
      sep.textContent = ', ';

      element.appendChild(sep);
    }

  }
}


