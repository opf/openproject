import {WorkPackageTableSelection} from '../../wp-fast-table/state/wp-table-selection.service';
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

import {wpControllersModule} from '../../../angular-modules';
import {WorkPackageViewController} from '../wp-view-base/wp-view-base.controller';

export class WorkPackageDetailsController extends WorkPackageViewController {

  constructor(public $injector,
              public $scope,
              public wpTableSelection:WorkPackageTableSelection,
              public $rootScope,
              public $state) {
    super($injector, $scope, $state.params['workPackageId']);
    this.observeWorkPackage();

    let wpId = $state.params['workPackageId'];
    let focusState = this.states.focusedWorkPackage;
    let focusedWP = focusState.getCurrentValue();

    if (!focusedWP) {
      focusState.put(wpId);
      this.wpTableSelection.setRowState(wpId, true);
    }

    this.states.focusedWorkPackage.observe($scope).subscribe((wpId) => {
      if ($state.includes('work-packages.list.details')) {
        $state.go(
          $state.current.name,
          { workPackageId: wpId }
        );
      }
    });
  }

  public onWorkPackageSave() {
    this.$rootScope.$emit('workPackagesRefreshInBackground');
  };
}

wpControllersModule.controller('WorkPackageDetailsController', WorkPackageDetailsController);
