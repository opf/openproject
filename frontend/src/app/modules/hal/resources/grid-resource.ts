//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {Attachable} from "core-app/modules/hal/resources/mixins/attachable-mixin";

export interface GridResourceLinks {
  update(payload:unknown):Promise<unknown>;
  updateImmediately(payload:unknown):Promise<unknown>;
  delete():Promise<unknown>;
}

export class GridBaseResource extends HalResource {
  public widgets:GridWidgetResource[];
  public name:string;
  public options:{[key:string]:unknown};
  public rowCount:number;
  public columnCount:number;

  public $initialize(source:any) {
    super.$initialize(source);

    this.widgets = this
      .widgets
      .map((widget:Object) => {
        let widgetResource = new GridWidgetResource( this.injector,
                                                     widget,
                                                     true,
                                                     this.halInitializer,
                                                     'GridWidget'
                                                   );

        widgetResource.grid = this;

        return widgetResource;
      });
  }

  readonly attachmentsBackend = true;

  public async updateAttachments():Promise<HalResource> {
    return this.attachments.$update().then(() => {
      this.states.forResource(this)!.putValue(this);
      return this.attachments;
    });
  }
}


export const GridResource = Attachable(GridBaseResource);

export interface GridResource extends Partial<GridResourceLinks>, GridBaseResource {
}
