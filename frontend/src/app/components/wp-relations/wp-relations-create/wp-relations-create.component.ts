import { RelationResource } from 'core-app/modules/hal/resources/relation-resource';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { WorkPackageRelationsService } from '../wp-relations.service';
import { Component, Input } from "@angular/core";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { HalEventsService } from "core-app/modules/hal/services/hal-events.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";

@Component({
  selector: 'wp-relations-create',
  templateUrl: './wp-relation-create.template.html'
})
export class WorkPackageRelationsCreateComponent {
  @Input() readonly workPackage:WorkPackageResource;

  public showRelationsCreateForm = false;
  public selectedRelationType:string = RelationResource.DEFAULT();
  public selectedWpId:string;
  public relationTypes = RelationResource.LOCALIZED_RELATION_TYPES(false);

  public isDisabled = false;

  public text = {
    abort: this.I18n.t('js.relation_buttons.abort'),
    relationType: this.I18n.t('js.relation_buttons.relation_type'),
    addNewRelation: this.I18n.t('js.relation_buttons.add_new_relation')
  };

  constructor(readonly I18n:I18nService,
              protected wpRelations:WorkPackageRelationsService,
              protected notificationService:WorkPackageNotificationService,
              protected halEvents:HalEventsService) {
  }


  public createRelation() {

    if (!this.selectedRelationType || !this.selectedWpId) {
      return;
    }

    this.isDisabled = true;
    this.createCommonRelation()
      .catch(() => this.isDisabled = false)
      .then(() => this.isDisabled = false);
  }

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
      .then(relation => {
        this.halEvents.push(this.workPackage, {
          eventType: 'association',
          relatedWorkPackage: relation.id!,
          relationType: this.selectedRelationType
        });
        this.notificationService.showSave(this.workPackage);
        this.toggleRelationsCreateForm();
      })
      .catch(err => {
        this.notificationService.handleRawError(err, this.workPackage);
        this.toggleRelationsCreateForm();
      });
  }

  public toggleRelationsCreateForm() {
    this.showRelationsCreateForm = !this.showRelationsCreateForm;
    // Reset value
    this.selectedWpId = '';
  }
}
