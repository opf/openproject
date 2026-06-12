// -- copyright
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

import {
  ChangeDetectionStrategy,
  Component,
  inject,
  Input,
  OnInit,
} from '@angular/core';

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UIRouterGlobals } from '@uirouter/core';

@Component({
  selector: 'op-project-attributes-tab',
  templateUrl: './op-project-attributes-tab.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageProjectAttributesTabComponent implements OnInit {
  readonly I18n = inject(I18nService);
  readonly uiRouterGlobals = inject(UIRouterGlobals);
  readonly pathHelper = inject(PathHelperService);

  public turboFrameSrc:string;
  public workPackageId:string;

  @Input() public workPackage:WorkPackageResource;

  ngOnInit() {
    const { workPackageId } = this.uiRouterGlobals.params as unknown as { workPackageId:string };
    this.workPackageId = (this.workPackage.id!) || workPackageId;

    this.turboFrameSrc = this.buildTurboFrameSrc();
  }

  protected buildTurboFrameSrc():string {
    const baseUrl = window.location.origin;
    const url = new URL(`${this.pathHelper.staticBase}/work_packages/${this.workPackageId}/project_attributes`, baseUrl);

    return url.toString();
  }
}
