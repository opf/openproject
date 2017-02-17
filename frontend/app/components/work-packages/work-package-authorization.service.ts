//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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


import {opWorkPackagesModule} from '../../angular-modules';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';

var $state:ng.ui.IStateService;
var PathHelper:any;

export class WorkPackageAuthorization {

  public project:any;

  constructor(public workPackage:WorkPackageResourceInterface) {
    this.project = workPackage.project;
  }

  public get allActions():any {
    return {
      workPackage: this.workPackage,
      project: this.project
    };
  }

  public copyLink() {
    const stateName = $state.current.name as string;
    if (stateName.indexOf('work-packages.show') === 0) {
      return PathHelper.workPackageCopyPath(this.workPackage.id);
    }
    else if (stateName.indexOf('work-packages.list.details') === 0) {
      return PathHelper.workPackageDetailsCopyPath(this.project.identifier, this.workPackage.id);
    }
  }

  public linkForAction(action:any) {
    if (action.key === 'copy') {
      action.link = this.copyLink();
    }
    else {
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

function wpAuthorizationService(...args:any[]) {
  [$state, PathHelper] = args;
  return WorkPackageAuthorization;
}

wpAuthorizationService.$inject = [
  '$state',
  'PathHelper'
];

opWorkPackagesModule.factory('WorkPackageAuthorization', wpAuthorizationService);
