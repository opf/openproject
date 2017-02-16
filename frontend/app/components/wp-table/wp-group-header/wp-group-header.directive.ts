// -- copyright
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
// ++

import {wpDirectivesModule} from '../../../angular-modules';

export class WorkPackageGroupHeaderController {
  constructor(public $scope:any, public I18n:op.I18n) {
    this.pushGroup(this.currentGroup);
  }

  public get resource() {
    return this.$scope.resource;
  }

  public get currentGroup() {
    return this.$scope.row.groupName;
  }

  public get currentGroupObject() {
    return this.$scope.groupHeaders[this.currentGroup];
  }

  /**
   * Return the group name. As the internal value may be emtpy (''),
   * we return the default placeholder in that case.
   */
  public get currentGroupName() {
    const value = this.currentGroupObject.value;

    if (value === '') {
      return this.I18n.t('js.placeholders.default');
    }

    return value;
  }

  public toggleCurrentGroup() {
    this.$scope.groupExpanded[this.currentGroup] = !this.$scope.groupExpanded[this.currentGroup];
  }

  public pushGroup(group:any) {
    if (this.$scope.groupExpanded[group] === undefined) {
      this.$scope.groupExpanded[group] = true;
    }
  }
}

function wpGroupHeader() {
  return {
    restrict: 'A',
    controller: WorkPackageGroupHeaderController,
    controllerAs: '$ctrl',
    bindToController: true,
  };
}

wpDirectivesModule.directive('wpGroupHeader', wpGroupHeader);
