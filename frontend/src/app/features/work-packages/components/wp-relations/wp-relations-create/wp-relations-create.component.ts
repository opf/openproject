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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { WorkPackageRelationsService } from '../wp-relations.service';

@Component({
  selector: 'wp-relations-create',
  templateUrl: './wp-relation-create.template.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WorkPackageRelationsCreateComponent {
  readonly I18n = inject(I18nService);
  protected wpRelations = inject(WorkPackageRelationsService);
  protected notificationService = inject(WorkPackageNotificationService);
  protected halEvents = inject(HalEventsService);
  protected cdRef = inject(ChangeDetectorRef);

  @Input() readonly workPackage:WorkPackageResource;

  public showRelationsCreateForm = false;

  public selectedRelationType:string = RelationResource.DEFAULT();

  public selectedWpId:string;

  public relationTypes = RelationResource.LOCALIZED_RELATION_TYPES(false);

  public isDisabled = false;

  public text = {
    abort: this.I18n.t('js.relation_buttons.abort'),
    relationType: this.I18n.t('js.relation_buttons.relation_type'),
    addNewRelation: this.I18n.t('js.relation_buttons.add_new_relation'),
  };

  public onSelected(workPackage?:WorkPackageResource) {
    if (workPackage) {
      this.selectedWpId = workPackage.id!;
      this.createCommonRelation();
    }
  }

  protected createCommonRelation() {
    return this.wpRelations.addCommonRelation(this.workPackage.id!,
      this.selectedRelationType,
      this.selectedWpId)
      .then((relation) => {
        this.halEvents.push(this.workPackage, {
          eventType: 'association',
          relatedWorkPackage: relation.id!,
          relationType: this.selectedRelationType,
        });
        this.notificationService.showSave(this.workPackage);
        this.wpRelations.updateCounter(this.workPackage);
        this.toggleRelationsCreateForm();
      })
      .catch((err) => {
        this.notificationService.handleRawError(err, this.workPackage);
        this.toggleRelationsCreateForm();
      });
  }

  public toggleRelationsCreateForm() {
    this.showRelationsCreateForm = !this.showRelationsCreateForm;
    // Reset value
    this.selectedWpId = '';
    this.cdRef.markForCheck();
  }
}
