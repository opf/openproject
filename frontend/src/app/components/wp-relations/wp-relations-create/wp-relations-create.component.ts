import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {Component, ElementRef, Inject, Input, ViewChild} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageEventsService} from "core-app/modules/work_packages/events/work-package-events.service";

@Component({
  selector: 'wp-relations-create',
  templateUrl: './wp-relation-create.template.html'
})
export class WorkPackageRelationsCreateComponent {
  @Input() readonly workPackage:WorkPackageResource;

  public showRelationsCreateForm:boolean = false;
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
              protected wpNotificationsService:WorkPackageNotificationService,
              protected wpEvents:WorkPackageEventsService,
              protected wpCacheService:WorkPackageCacheService) {
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
        this.wpEvents.push({
          type: 'association',
          id: this.workPackage.id!,
          relatedWorkPackage: relation.id!,
          relationType: this.selectedRelationType
        });
        this.wpNotificationsService.showSave(this.workPackage);
        this.toggleRelationsCreateForm();
      })
      .catch(err => {
        this.wpNotificationsService.handleRawError(err, this.workPackage);
        this.toggleRelationsCreateForm();
      });
  }

  public toggleRelationsCreateForm() {
    this.showRelationsCreateForm = !this.showRelationsCreateForm;
    // Reset value
    this.selectedWpId = '';
  }
}
