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

import {WorkPackageEditContext} from './work-package-edit-context';
import {WorkPackageTableRow} from '../wp-fast-table/wp-table.interfaces';
import { CellBuilder, tdClassName, editCellContainer } from '../wp-fast-table/builders/cell-builder';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';
import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {rowId} from '../wp-fast-table/helpers/wp-table-row-helpers';
import {States} from '../states.service';

export class TableRowEditContext implements WorkPackageEditContext {
  // Injections
  public wpCacheService:WorkPackageCacheService;
  public wpTableColumns:WorkPackageTableColumnsService;
  public states:States;
  public $rootScope:ng.IRootScopeService;
  public FocusHelper:any;

  // Use cell builder to reset edit fields
  private cellBuilder = new CellBuilder();

  constructor(public workPackageId:string) {
    injectorBridge(this);
  }

  public findContainer(fieldName:string):JQuery {
    return jQuery(`#${rowId(this.workPackageId)} .${tdClassName}.${fieldName} .${editCellContainer}`);
  }

  public reset(workPackage:WorkPackageResource, fieldName:string, focus?:boolean) {
    const cell = this.findContainer(fieldName);
    this.cellBuilder.refresh(cell[0], workPackage, fieldName);

    if (focus) {
      this.FocusHelper.focusElement(cell);
    }
  }

  public requireVisible(fieldName:string):Promise<JQuery> {
    this.wpTableColumns.addColumn(fieldName);
    let updated = this.states.table.rendered.get();
    return updated.then(() => {
      return this.findContainer(fieldName);
    });
  }

  public firstField(names:string[]) {
    return 'subject';
  }

  public onSaved(workPackage:WorkPackageResource) {
    this.$rootScope.$emit('workPackagesRefreshInBackground');
  }
}

TableRowEditContext.$inject = [
  'wpCacheService', 'states', 'wpTableColumns', '$rootScope', 'FocusHelper'
];
