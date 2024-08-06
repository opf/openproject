//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++


import { DisplayField } from "core-app/shared/components/fields/display/display-field.module";
import { IFieldSchema } from "core-app/shared/components/fields/field.base";
import { InjectField } from "core-app/shared/helpers/angular/inject-field.decorator";
import { ApiV3Service } from "core-app/core/apiv3/api-v3.service";

interface ICostsByType {
    costObjectId:string;
    costType:{
        name:string;
        id:string;
    };
    staticPath:{
        href:string;
    };
    spentUnits:number;
}

export class CostsByTypeDisplayField extends DisplayField {

    @InjectField() apiV3Service:ApiV3Service;

    public apply(resource:any, schema:IFieldSchema) {
      super.apply(resource, schema);
      this.loadIfNecessary();
    }

    protected loadIfNecessary() {
      if (this.value && this.value.$loaded === false) {
        this.value.$load().then(() => {

          if (this.resource.$source._type === 'WorkPackage') {
            this
              .apiV3Service
              .work_packages
              .cache
              .touch(this.resource.id!);
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

      link.href = showCosts.href + '&unit=' + val.costType.id;
      link.setAttribute('target', '_blank');
      link.textContent = val.spentUnits + ' ' + val.costType.name;
      element.appendChild(link);

      this.addSeparator(element, i);
    }

    /**
   * Render text
   */
    private renderCostAsText(val:ICostsByType, element:HTMLElement, i:number) {
      const span = document.createElement('span');
      span.textContent = val.spentUnits + ' ' + val.costType.name;
      element.appendChild(span);
      this.addSeparator(element, i);
    }

    private addSeparator(element:HTMLElement, i:number) {
      if (i < this.value.elements.length - 1) {
        const sep = document.createElement('span');
        sep.textContent = ', ';

        element.appendChild(sep);
      }
    }
}


