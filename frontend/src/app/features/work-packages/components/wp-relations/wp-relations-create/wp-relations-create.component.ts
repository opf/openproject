import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  Component,
  Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { WorkPackageRelationsService } from '../wp-relations.service';

@Component({
  selector: 'wp-relations-create',
  templateUrl: './wp-relation-create.template.html',
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
    addNewRelation: this.I18n.t('js.relation_buttons.add_new_relation'),
  };

  constructor(
    readonly I18n:I18nService,
    protected wpRelations:WorkPackageRelationsService,
    protected notificationService:WorkPackageNotificationService,
    protected halEvents:HalEventsService,
  ) {
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
  }
}
