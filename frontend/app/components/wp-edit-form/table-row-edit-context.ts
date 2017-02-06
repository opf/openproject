import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';
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
import {tdClassName, CellBuilder} from '../wp-fast-table/builders/cell-builder';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {locateRow} from '../wp-fast-table/helpers/wp-table-row-helpers';
import {States} from '../states.service';

export class TableRowEditContext implements WorkPackageEditContext {
  // Injections
  public wpCacheService:WorkPackageCacheService;
  public wpTableColumns:WorkPackageTableColumnsService;
  public states:States;
  public $rootScope:ng.IRootScopeService;

  // Use cell builder to reset edit fields
  private cellBuilder = new CellBuilder();

  constructor(public row:WorkPackageTableRow) {
    injectorBridge(this);
  }

  public get rowElement():HTMLElement {
    return locateRow(this.row.workPackageId);
  }

  public find(fieldName:string):JQuery {
    return jQuery(this.rowElement).find(`.${tdClassName}.${fieldName}`);
  }

  public reset(workPackage, fieldName:string) {
    let element = this.find(fieldName);

    let newCell = this.cellBuilder.build(workPackage, fieldName);
    element.replaceWith(newCell);
  }

  public requireVisible(name:string):Promise<JQuery> {
    this.wpTableColumns.addColumn(name);
    let updated = this.states.table.rendered.observe(null).take(1).toPromise();
    return updated.then(() => {
      return this.find(name);
    })
  }

  public firstField(names:string[]) {
    return 'subject';
  }

  public onSaved(workPackage:WorkPackageResource) {
    this.$rootScope.$emit('workPackagesRefreshInBackground');
  }
}

TableRowEditContext.$inject = ['wpCacheService', 'states', 'wpTableColumns', '$rootScope'];
