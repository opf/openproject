//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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

import {Component, Input, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {WorkPackageRelationsHierarchyService} from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import {OpUnlinkTableAction} from 'core-components/wp-table/table-actions/actions/unlink-table-action';
import {OpTableActionFactory} from 'core-components/wp-table/table-actions/table-action';
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WorkPackageRelationQueryBase} from "core-components/wp-relations/embedded/wp-relation-query.base";
import {WpChildrenInlineCreateService} from "core-components/wp-relations/embedded/children/wp-children-inline-create.service";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {filter} from "rxjs/operators";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {GroupDescriptor} from "core-components/work-packages/wp-single-view/wp-single-view.component";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";

@Component({
  selector: 'wp-children-query',
  templateUrl: '../wp-relation-query.html',
  providers: [
    { provide: WorkPackageInlineCreateService, useClass: WpChildrenInlineCreateService }
  ]
})
export class WorkPackageChildrenQueryComponent extends WorkPackageRelationQueryBase implements OnInit {
  @Input() public workPackage:WorkPackageResource;
  @Input() public query:QueryResource;

  /** An optional group descriptor if we're rendering on the single view */
  @Input() public group?:GroupDescriptor;
  @Input() public addExistingChildEnabled:boolean = false;

  public tableActions:OpTableActionFactory[] = [
    OpUnlinkTableAction.factoryFor(
      'remove-child-action',
      this.I18n.t('js.relation_buttons.remove_child'),
      (child:WorkPackageResource) => {
        this.embeddedTable.loadingIndicator = this.wpRelationsHierarchyService.removeChild(child);
      },
      (child:WorkPackageResource) => !!child.changeParent
    )
  ];

  constructor(protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              protected PathHelper:PathHelperService,
              protected wpInlineCreate:WorkPackageInlineCreateService,
              protected halEvents:HalEventsService,
              protected wpCacheService:WorkPackageCacheService,
              protected queryUrlParamsHelper:UrlParamsHelperService,
              readonly I18n:I18nService) {
    super(queryUrlParamsHelper);
  }

  ngOnInit() {
    // Set reference target and reference class
    this.wpInlineCreate.referenceTarget = this.workPackage;

    // Set up the query props
    this.queryProps = this.buildQueryProps();

    // Fire event that children were added
    this.wpInlineCreate.newInlineWorkPackageCreated
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((toId:string) => {
        this.halEvents.push(this.workPackage, {
          eventType: 'association',
          relatedWorkPackage: toId,
          relationType: 'child'
        });
      });

    // Refresh table when work package is refreshed
    this.wpCacheService
      .observe(this.workPackage.id!)
      .pipe(
        filter(() => this.embeddedTable && this.embeddedTable.isInitialized),
        this.untilDestroyed()
      )
      .subscribe(() => this.refreshTable());
  }
}
