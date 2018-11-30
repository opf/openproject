import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {Component, ElementRef, Inject, Input, ViewChild} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'wp-relations-create',
  templateUrl: './wp-relation-create.template.html'
})
export class WorkPackageRelationsCreateComponent {
  @Input() readonly workPackage:WorkPackageResource;
  @ViewChild('focusAfterSave') readonly focusAfterSave:ElementRef;

  public showRelationsCreateForm:boolean = false;
  public selectedRelationType:string = RelationResource.DEFAULT();
  public selectedWpId:string;
  public relationTypes = RelationResource.LOCALIZED_RELATION_TYPES(false);

  public isDisabled = false;

  public text = {
    save: this.I18n.t('js.relation_buttons.save'),
    abort: this.I18n.t('js.relation_buttons.abort'),
    relationType: this.I18n.t('js.relation_buttons.relation_type'),
    addNewRelation: this.I18n.t('js.relation_buttons.add_new_relation')
  };

  constructor(readonly I18n:I18nService,
              protected wpRelations:WorkPackageRelationsService,
              protected wpNotificationsService:WorkPackageNotificationService,
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

  public updateSelectedId(workPackageId:string) {
    this.selectedWpId = workPackageId;
  }

  protected createCommonRelation() {
    return this.wpRelations.addCommonRelation(this.workPackage.id,
      this.selectedRelationType,
      this.selectedWpId)
      .then(relation => {
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

    setTimeout(() => {
      if (!this.showRelationsCreateForm) {
        // Reset value
        this.selectedWpId = '';
        this.focusAfterSave.nativeElement.focus();
      }
    });
  }
}
