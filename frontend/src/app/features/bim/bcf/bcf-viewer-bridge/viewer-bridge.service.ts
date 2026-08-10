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

import { Injectable, Injector, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { StateService } from '@uirouter/core';
import { CreateBcfViewpointData } from 'core-app/features/bim/bcf/api/bcf-api.model';

@Injectable()
export abstract class ViewerBridgeService {
  readonly injector = inject(Injector);

  @LazyInject() state:StateService;

  /**
   * Determine whether a viewer should be shown
   */
  abstract shouldShowViewer:boolean;

  /**
   * Get a viewpoint from the viewer
   */
  abstract getViewpoint$():Observable<CreateBcfViewpointData>;

  /**
   * Show the given viewpoint JSON in the viewer
   */
  abstract showViewpoint(workPackage:WorkPackageResource, index:number):void;

  /**
   * Determine whether a viewer is present to ensure we can show viewpoints
   */
  abstract viewerVisible():boolean;

  /**
   * Fires when viewer becomes visible.
   */
  abstract viewerVisible$:Observable<boolean>;
}
