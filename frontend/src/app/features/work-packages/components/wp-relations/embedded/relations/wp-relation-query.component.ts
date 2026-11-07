//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, Input, OnInit, SimpleChanges, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OpUnlinkTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/actions/unlink-table-action';
import { OpTableActionFactory } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageRelationQueryBase } from 'core-app/features/work-packages/components/wp-relations/embedded/wp-relation-query.base';
import { WpRelationInlineCreateService } from 'core-app/features/work-packages/components/wp-relations/embedded/relations/wp-relation-inline-create.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { Subscription } from 'rxjs';
import { filter } from 'rxjs/operators';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { GroupDescriptor } from 'core-app/features/work-packages/components/wp-single-view/wp-single-view.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-relation-query',
  templateUrl: '../wp-relation-query.html',
  providers: [
    { provide: WorkPackageInlineCreateService, useClass: WpRelationInlineCreateService },
  ],
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WorkPackageRelationQueryComponent extends WorkPackageRelationQueryBase implements OnInit {
  protected readonly PathHelper = inject(PathHelperService);
  protected readonly wpInlineCreate = inject(WorkPackageInlineCreateService) as WpRelationInlineCreateService;
  protected readonly wpRelations = inject(WorkPackageRelationsService);
  protected readonly halEvents = inject(HalEventsService);
  protected readonly notificationService = inject(WorkPackageNotificationService);
  protected readonly I18n = inject(I18nService);

  @Input() public workPackage:WorkPackageResource;

  @Input() public query:QueryResource|object;

  @Input() public group:GroupDescriptor;

  private relationsSubscription?:Subscription;

  public tableActions:OpTableActionFactory[] = [
    OpUnlinkTableAction.factoryFor(
      'remove-relation-action',
      this.I18n.t('js.relation_buttons.remove'),
      (relatedTo:WorkPackageResource) => {
        if (!this.embeddedTable) {
          return;
        }

        this.embeddedTable.loadingIndicator = this.wpRelations.require(relatedTo.id!)
          .then(() => this.wpInlineCreate.remove(this.workPackage, relatedTo))
          .then(() => this.refreshTable())
          .catch((error) => this.notificationService.handleRawError(error, this.workPackage));
      },
      (child:WorkPackageResource) => !!child.changeParent,
    ),
  ];

  public idFromLink = idFromLink;

  ngOnInit():void {
    // Wire the successful saving of a new addition to refreshing the embedded table
    this.wpInlineCreate.newInlineWorkPackageCreated
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((toId:string) => this.addRelation(toId));
  }

  override ngOnChanges(changes:SimpleChanges<WorkPackageRelationQueryComponent>):void {
    super.ngOnChanges(changes);
    this.wpInlineCreate.referenceTarget = this.workPackage;
    this.wpInlineCreate.relationType = this.getRelationTypeFromQuery();

    if (!changes.workPackage || changes.workPackage.previousValue?.id === this.workPackage.id) {
      return;
    }

    this.relationsSubscription?.unsubscribe();
    this.relationsSubscription = this.wpRelations.observe(this.workPackage.id!)
      .pipe(
        filter((relations) => !!relations && Object.keys(relations).length > 0),
        this.untilDestroyed(),
      )
      .subscribe(() => this.refreshTable());
  }

  private addRelation(toId:string) {
    const workPackage = this.workPackage;
    const relationType = this.getRelationTypeFromQuery();
    this.wpInlineCreate
      .add(workPackage, toId)
      .then(() => {
        this.halEvents.push(workPackage, {
          eventType: 'association',
          relatedWorkPackage: toId,
          relationType,
        });
      })
      .catch((error:unknown) => this.notificationService.handleRawError(error, workPackage));
  }

  private getRelationTypeFromQuery() {
    return this.group.relationType!;
  }
}
