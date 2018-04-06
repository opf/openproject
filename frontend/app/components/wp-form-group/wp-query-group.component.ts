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

import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';
import {OpUnlinkTableAction} from 'core-components/wp-table/table-actions/actions/unlink-table-action';
import {WorkPackageRelationsHierarchyService} from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import {Component, Inject, Input, OnDestroy, OnInit, ViewChild} from '@angular/core';
import {WorkPackageEmbeddedTableComponent} from 'core-components/wp-table/embedded/wp-embedded-table.component';
import {I18nToken, UrlParamsHelperServiceToken} from 'core-app/angular4-transition-utils';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {QueryResourceInterface} from 'core-components/api/api-v3/hal-resources/query-resource.service';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';

export interface QueryGroupDescriptor {
  name:string;
  query:QueryResourceInterface;
  type:string;
}

@Component({
  selector: 'wp-query-group',
  template: require('!!raw-loader!./wp-query-group.template.html')
})
export class WorkPackageFormQueryGroupComponent implements OnInit, OnDestroy {
  @Input() public workPackage:WorkPackageResourceInterface;
  @Input() public group:QueryResourceInterface;
  @ViewChild('childrenEmbeddedTable') private childrenEmbeddedTable:WorkPackageEmbeddedTableComponent;

  public canHaveChildren:boolean;
  public canModifyHierarchy:boolean;

  public childrenQueryProps:any;

  public childrenTableActions = [
    OpUnlinkTableAction.factoryFor(
      'remove-child-action',
      this.I18n.t('js.relation_buttons.remove_child'),
      (child:WorkPackageResourceInterface) => {
        this.childrenEmbeddedTable.loadingIndicator = this.wpRelationsHierarchyService
          .removeChild(child)
          .then(() => this.refreshTable());
      })
  ];

  constructor(protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              protected PathHelper:PathHelperService,
              @Inject(UrlParamsHelperServiceToken) protected queryUrlParamsHelper:UrlParamsHelperService,
              @Inject(I18nToken) protected I18n:op.I18n) {
  }

  ngOnInit() {
    this.canHaveChildren = !this.workPackage.isMilestone;
    this.canModifyHierarchy = !!this.workPackage.changeParent;

    this.childrenQueryProps = this.queryUrlParamsHelper.buildV3GetQueryFromQueryResource(this.contextualizedQuery,
                                                                                        {})
  }

  ngOnDestroy() {
    // Nothing to do
  }

  public refreshTable() {
    this.childrenEmbeddedTable.refresh();
  }

  private get contextualizedQuery() {
    let duppedQuery = _.clone(this.group.query)

    _.each(duppedQuery.filters, (filter) => {
      if (filter._links.values[0].templated) {
        filter._links.values[0].href = filter._links.values[0].href.replace('{id}', this.workPackage.id);
      }
    });

    return duppedQuery;
  }
}
