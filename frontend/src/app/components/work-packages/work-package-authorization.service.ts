//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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


import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { StateService } from '@uirouter/core';
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";

export class WorkPackageAuthorization {

  public project:any;

  constructor(public workPackage:WorkPackageResource,
              readonly PathHelper:PathHelperService,
              readonly $state:StateService) {
    this.project = workPackage.project;
  }

  public get allActions():any {
    return {
      workPackage: this.workPackage,
      project: this.project
    };
  }

  public copyLink() {
    const stateName = this.$state.current.name as string;
    if (stateName.indexOf('work-packages.partitioned.list.details') === 0) {
      return this.PathHelper.workPackageDetailsCopyPath(this.project.identifier, this.workPackage.id!);
    } else {
      return this.PathHelper.workPackageCopyPath(this.workPackage.id!);
    }
  }

  public linkForAction(action:any) {
    if (action.key === 'copy') {
      action.link = this.copyLink();
    } else {
      action.link = this.allActions[action.resource][action.link].href;
    }

    return action;
  }

  public isPermitted(action:any) {
    return this.allActions[action.resource] !== undefined &&
      this.allActions[action.resource][action.link] !== undefined;
  }

  public permittedActionKeys(allowedActions:any) {
    var validActions = _.filter(allowedActions, (action:any) => this.isPermitted(action));

    return _.map(validActions, function (action:any) {
      return action.key;
    });
  }

  public permittedActionsWithLinks(allowedActions:any) {
    var validActions = _.filter(_.cloneDeep(allowedActions), (action:any) => this.isPermitted(action));

    var allowed = _.map(validActions, (action:any) => this.linkForAction(action));

    return allowed;
  }
}
