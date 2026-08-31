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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectorRef, Injectable, inject } from '@angular/core';
import { GridWidgetArea } from 'core-app/shared/components/grids/areas/grid-widget-area';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';

@Injectable()
export class GridRemoveWidgetService {
  readonly cdRef = inject(ChangeDetectorRef);
  readonly layout = inject(GridAreaService);

  public area(area:GridWidgetArea) {
    return this.widget(area.widget);
  }

  public widget(widget:GridWidgetResource):Promise<GridResource> {
    return this.layout
      .removeWidget(widget)
      .finally(() => this.cdRef.detectChanges());
  }
}
