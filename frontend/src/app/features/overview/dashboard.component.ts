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

import { ChangeDetectionStrategy, Component, ElementRef, inject, Input, OnInit } from '@angular/core';
import { GridPageComponent } from 'core-app/shared/components/grids/grid/page/grid-page.component';
import { GRID_PROVIDERS } from 'core-app/shared/components/grids/grid/grid.component';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectGridsModule } from 'core-app/shared/components/grids/openproject-grids.module';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

// The OnPush change detection strategy makes the page very slow, especially removing widgets. See #66753
// TODO: Investigate whether this can be migrated to OnPush after zoneless testing.
@Component({
  templateUrl: '../../shared/components/grids/grid/page/grid-page.component.html',
  styleUrls: ['../../shared/components/grids/grid/page/grid-page.component.sass'],
  imports: [
    OpSharedModule,
    OpenprojectGridsModule,
  ],
  providers: GRID_PROVIDERS,
  standalone: true,
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class DashboardComponent extends GridPageComponent implements OnInit {
  @Input() projectIdentifier:string;

  readonly elementRef = inject(ElementRef);

  ngOnInit() {
    populateInputsFromDataset(this);
    super.ngOnInit();
  }

  protected gridScopePath():string {
    return this.pathHelper.projectDashboardsPath(this.projectIdentifier);
  }
}
