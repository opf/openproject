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

import {Component, Inject, Input, OnDestroy, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {OpUnlinkTableAction} from 'core-components/wp-table/table-actions/actions/unlink-table-action';
import {OpTableActionFactory} from 'core-components/wp-table/table-actions/table-action';
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageRelationQueryBase} from "core-components/wp-relations/embedded/wp-relation-query.base";
import {WpRelationInlineCreateService} from "core-components/wp-relations/embedded/relations/wp-relation-inline-create.service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {forkJoin, merge} from "rxjs";
import {WorkPackageRelationsService} from "core-components/wp-relations/wp-relations.service";

@Component({
  selector: 'wp-relation-query',
  templateUrl: '../wp-relation-query.html',
  providers: [
    { provide: WorkPackageInlineCreateService, useClass: WpRelationInlineCreateService }
  ]
})
export class WorkPackageRelationQueryComponent extends WorkPackageRelationQueryBase implements OnInit, OnDestroy {
  @Input() public workPackage:WorkPackageResource;

  @Input() public query:any;
  @Input() public group:any;

  public tableActions:OpTableActionFactory[] = [
    OpUnlinkTableAction.factoryFor(
      'remove-relation-action',
      this.I18n.t('js.relation_buttons.remove'),
      (relatedTo:WorkPackageResource) => {
        this.embeddedTable.loadingIndicator = this.wpRelations.require(relatedTo.id)
          .then(() => this.wpInlineCreate.remove(this.workPackage, relatedTo))
          .then(() => this.refreshTable())
          .catch((error) => this.wpNotifications.handleRawError(error, this.workPackage));
      },
      (child:WorkPackageResource) => !!child.changeParent
    )
  ];

  constructor(protected readonly PathHelper:PathHelperService,
              @Inject(WorkPackageInlineCreateService) protected readonly wpInlineCreate:WpRelationInlineCreateService,
              protected readonly wpRelations:WorkPackageRelationsService,
              protected readonly queryUrlParamsHelper:UrlParamsHelperService,
              protected readonly wpNotifications:WorkPackageNotificationService,
              protected readonly I18n:I18nService) {
    super(queryUrlParamsHelper);
  }

  ngOnInit() {
    let relationType = this.getRelationTypeFromQuery();

    // Set reference target and reference class
    this.wpInlineCreate.referenceTarget = this.workPackage;
    this.wpInlineCreate.relationType = relationType;

    // Set up the query props
    this.buildQueryProps();

    // Wire the successful saving of a new addition to refreshing the embedded table
    this.wpInlineCreate.newInlineWorkPackageCreated
      .pipe(untilComponentDestroyed(this))
      .subscribe((toId:string) => this.addRelation(toId));

    // When relations have changed, refresh this table

    this.wpRelations.observe(this.workPackage.id)
      .pipe(untilComponentDestroyed(this))
      .subscribe(() => this.refreshTable());
  }

  ngOnDestroy() {
    // Nothing to do
  }

  private addRelation(toId:string) {
    this.wpInlineCreate
      .add(this.workPackage, toId)
      .catch(error => this.wpNotifications.handleRawError(error, this.workPackage));
  }

  private getRelationTypeFromQuery() {
    return this.group.relationType;
  }
}
