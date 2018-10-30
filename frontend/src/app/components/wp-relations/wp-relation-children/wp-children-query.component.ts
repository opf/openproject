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

import {Component, Input, OnDestroy, OnInit, ViewChild} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {WorkPackageRelationsHierarchyService} from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WorkPackageEmbeddedTableComponent} from 'core-components/wp-table/embedded/wp-embedded-table.component';
import {OpUnlinkTableAction} from 'core-components/wp-table/table-actions/actions/unlink-table-action';
import {OpTableActionFactory} from 'core-components/wp-table/table-actions/table-action';
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageInlineAddExistingChildService} from "core-components/wp-relations/wp-relation-add-child/wp-inline-add-existing-child.service";

@Component({
  selector: 'wp-children-query',
  templateUrl: './wp-children-query.html',
  providers: [
    { provide: WorkPackageInlineCreateService, useClass: WorkPackageInlineAddExistingChildService }
  ]
})
export class WorkPackageChildrenQueryComponent implements OnInit, OnDestroy {
  @Input() public workPackage:WorkPackageResource;
  @Input() public query:any;
  @Input() public addExistingChildEnabled:boolean = false;
  @ViewChild('childrenEmbeddedTable') private childrenEmbeddedTable:WorkPackageEmbeddedTableComponent;

  public canHaveChildren:boolean;
  public canModifyHierarchy:boolean;

  public childrenQueryProps:any;

  public childrenTableActions:OpTableActionFactory[] = [
    OpUnlinkTableAction.factoryFor(
      'remove-child-action',
      this.I18n.t('js.relation_buttons.remove_child'),
      (child:WorkPackageResource) => {
        this.childrenEmbeddedTable.loadingIndicator = this.wpRelationsHierarchyService
          .removeChild(child)
          .then(() => this.refreshTable());
      },
      (child:WorkPackageResource) => !!child.changeParent
    )
  ];

  constructor(protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              protected PathHelper:PathHelperService,
              protected wpInlineCreate:WorkPackageInlineCreateService,
              protected queryUrlParamsHelper:UrlParamsHelperService,
              readonly I18n:I18nService) {
  }

  ngOnInit() {
    // Set reference target and reference class
    this.wpInlineCreate.referenceTarget = this.workPackage;

    // Wire the successful saving of a new addition to refreshing the embedded table
    this.wpInlineCreate.newInlineWorkPackageReferenced
      .pipe(untilComponentDestroyed(this))
      .subscribe(() => this.refreshTable());

    this.canHaveChildren = !this.workPackage.isMilestone;
    this.canModifyHierarchy = !!this.workPackage.changeParent;

    if (this.query && this.query._type === 'Query') {
      this.childrenQueryProps = this.queryUrlParamsHelper.buildV3GetQueryFromQueryResource(this.contextualizedQuery,
        {});
    } else {
      this.childrenQueryProps = this.query;
    }
  }

  ngOnDestroy() {
    // Nothing to do
  }

  public refreshTable() {
    this.childrenEmbeddedTable.refresh();
  }

  private get contextualizedQuery() {
    let duppedQuery = _.cloneDeep(this.query);

    _.each(duppedQuery.filters, (filter) => {
      if (filter._links.values[0] && filter._links.values[0].templated) {
        filter._links.values[0].href = filter._links.values[0].href.replace('{id}', this.workPackage.id);
      }
    });

    return duppedQuery;
  }
}
