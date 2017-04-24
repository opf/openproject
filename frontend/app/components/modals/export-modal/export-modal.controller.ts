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

import {wpControllersModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {WorkPackageCollectionResource} from '../../api/api-v3/hal-resources/wp-collection-resource.service';
import {HalResource} from '../../api/api-v3/hal-resources/hal-resource.service';
import {HalLink} from '../../api/api-v3/hal-link/hal-link.service';
import {WorkPackageTableColumnsService} from '../../wp-fast-table/state/wp-table-columns.service';

interface ExportLink extends HalLink {
  identifier:string;
}

class ExportModalController {
  public name: string;
  public closeMe: Function;
  public exportOptions: any;

  constructor(exportModal:any,
              private UrlParamsHelper:any,
              private states:States,
              private wpTableColumns:WorkPackageTableColumnsService) {
    var results = this.states.table.results.value!;

    this.name = 'Export';
    this.closeMe = exportModal.deactivate;
    this.exportOptions = this.buildExportOptions(results);
  }

  private buildExportOptions(results:WorkPackageCollectionResource) {
    return results.representations.map(format => {
      const link = format.$link as ExportLink;

      return {
        identifier: link.identifier,
        label: link.title,
        url: this.addColumnsToHref(format.href!)
      };
    });
  }

  private addColumnsToHref(href:string) {
    let columns = this.wpTableColumns.getColumns();

    let columnIds = columns.map(function(column) { return column.id; });

    return href + "&" + this.UrlParamsHelper.buildQueryString({'columns[]': columnIds});
  }
}

wpControllersModule.controller('ExportModalController', ExportModalController);
