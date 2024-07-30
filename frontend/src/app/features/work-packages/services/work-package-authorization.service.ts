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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { StateService } from '@uirouter/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageAction } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';

export class WorkPackageAuthorization {
  public project:ProjectResource;

  constructor(public workPackage:WorkPackageResource,
    readonly PathHelper:PathHelperService,
    readonly $state:StateService) {
    this.project = workPackage.project as ProjectResource;
  }

  public linkForAction(action:WorkPackageAction):WorkPackageAction {
    let link:string;
    switch (action.key) {
      case 'copy':
        link = this.copyLink();
        break;
      case 'copy_link_to_clipboard':
        link = this.shortLink();
        break;
      case 'copy_to_other_project':
        link = this.bulkCopyLink();
        break;
      default:
        link = (this.workPackage[action.link as string] as HalLink).href as string;
    }

    return { ...action, link };
  }

  public isPermitted(action:WorkPackageAction):boolean {
    return this.workPackage[action.link as string] !== undefined;
  }

  public permittedActionKeys(allowedActions:WorkPackageAction[]):string[] {
    return allowedActions
      .filter((action) => this.isPermitted(action))
      .map((action) => action.key);
  }

  public permittedActionsWithLinks(allowedActions:WorkPackageAction[]):WorkPackageAction[] {
    return allowedActions
      .filter((action) => this.isPermitted(action))
      .map((action) => this.linkForAction(action));
  }

  private copyLink() {
    const stateName = this.$state.current.name as string;
    if (stateName.indexOf('work-packages.partitioned.list.details') === 0) {
      return this.PathHelper.workPackageDetailsCopyPath(this.project.identifier, this.workPackage.id as string);
    }
    return this.PathHelper.workPackageCopyPath(this.workPackage.id as string);
  }

  private shortLink() {
    return this.PathHelper.workPackageShortPath(this.workPackage.id as string);
  }

  private bulkCopyLink():string {
    return `${this.PathHelper.staticBase}/work_packages/move/new?copy=true&ids[]=${this.workPackage.id as string}`;
  }
}
