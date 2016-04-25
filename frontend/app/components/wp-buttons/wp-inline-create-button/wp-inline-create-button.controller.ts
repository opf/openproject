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

import {wpButtonsModule} from '../../../angular-modules';
import WorkPackageCreateButtonController from '../wp-create-button/wp-create-button.controller';

class WorkPackageInlineCreateButtonController extends WorkPackageCreateButtonController {
  public query: op.Query;
  public rows:any[];
  public hidden:boolean = false;
  private _wp;
  private availableProjects = [];

  constructor(
    protected $state,
    protected $scope,
    protected $rootScope,
    protected $element,
    protected I18n,
    protected ProjectService,
    protected WorkPackageResource,
    protected apiWorkPackages
  ) {
    super($state, I18n, ProjectService);

    $rootScope.$on('workPackageSaved', (_event, savedWp) => {
      // Add another row
      if (savedWp === this._wp) {
        this.addWorkPackageRow();
      }
    });

    this.apiWorkPackages.availableProjects().then(resource => {
      this.canCreate = (resource && resource.total > 0);
      this.availableProjects = resource.elements;
    });

    $rootScope.$on('inlineWorkPackageCreateCancelled', (_event, index, row) => {
      if (row.object === this._wp) {
        this.rows.splice(index, 1);
        this.show();
      }
    });
  }

  public isDisabled() {
    return !this.canCreate || this.$state.includes('**.new');
  }

  public addWorkPackageRow() {
    this.WorkPackageResource.fromCreateForm(this.availableProjects[0].identifier).then(wp => {
      this._wp = wp;
      wp.inlineCreated = true;

      this.query.applyDefaultsFromFilters(this._wp);

      this.rows.push({ level: 0, ancestors: [], object: wp, parent: void 0 });
      this.hide();
    });
  }

  public hide() {
    return this.hidden = true;
  }

  public show() {
    return this.hidden = false;
  }
}

wpButtonsModule.controller(
  'WorkPackageInlineCreateButtonController', WorkPackageInlineCreateButtonController);
