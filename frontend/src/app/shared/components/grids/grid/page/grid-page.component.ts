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

import { ChangeDetectorRef, Directive, inject, OnDestroy, OnInit, Renderer2 } from '@angular/core';
import { GridInitializationService } from 'core-app/shared/components/grids/grid/initialization.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridAddWidgetService } from 'core-app/shared/components/grids/grid/add-widget.service';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Directive()
export abstract class GridPageComponent implements OnInit, OnDestroy {
  readonly gridInitialization = inject(GridInitializationService);
  readonly pathHelper = inject(PathHelperService);
  readonly currentProject = inject(CurrentProjectService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly addWidget = inject(GridAddWidgetService);
  readonly renderer = inject(Renderer2);
  readonly areas = inject(GridAreaService);
  readonly configurationService = inject(ConfigurationService);

  public grid:GridResource;

  ngOnInit() {
    this.renderer.addClass(document.body, 'widget-grid-layout');
    this
      .gridInitialization
      .initialize(this.gridScopePath())
      .subscribe((grid) => {
        this.grid = grid;
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy():void {
    this.renderer.removeClass(document.body, 'widget-grid-layout');
  }

  protected abstract gridScopePath():string;
}
