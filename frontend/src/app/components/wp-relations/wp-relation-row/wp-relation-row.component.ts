import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {Component, ElementRef, Inject, Input, OnInit, ViewChild} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";


@Component({
  selector: 'wp-relation-row',
  templateUrl: './wp-relation-row.template.html'
})
export class WorkPackageRelationRowComponent implements OnInit {
  @Input() public workPackage:WorkPackageResource;
  @Input() public relatedWorkPackage:WorkPackageResource;
  @Input() public groupByWorkPackageType:boolean;

  @ViewChild('relationDescriptionTextarea') readonly relationDescriptionTextarea:ElementRef;

  public relationType:string;
  public showRelationInfo:boolean = false;
  public showEditForm:boolean = false;
  public availableRelationTypes:{ label:string, name:string }[];
  public selectedRelationType:{ name:string };

  public userInputs = {
    newRelationText: '',
    showDescriptionEditForm: false,
    showRelationTypesForm: false,
    showRelationInfo: false,
  };

  // Create a quasi-field object
  public fieldController = {
    handler: {
      active: true,
    },
    required: false
  };

  public relation:RelationResource;
  public text = {
    cancel: this.I18n.t('js.button_cancel'),
    save: this.I18n.t('js.button_save'),
    removeButton: this.I18n.t('js.relation_buttons.remove'),
    description_label: this.I18n.t('js.relation_buttons.update_description'),
    toggleDescription: this.I18n.t('js.relation_buttons.toggle_description'),
    updateRelation: this.I18n.t('js.relation_buttons.update_relation'),
    placeholder: {
      description: this.I18n.t('js.placeholders.relation_description')
    }
  };

  constructor(protected wpCacheService:WorkPackageCacheService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected wpRelations:WorkPackageRelationsService,
              readonly I18n:I18nService,
              protected PathHelper:PathHelperService) {
  }

  ngOnInit() {
    this.relation = this.relatedWorkPackage.relatedBy as RelationResource;

    this.userInputs.newRelationText = this.relation.description || '';
    this.availableRelationTypes = RelationResource.LOCALIZED_RELATION_TYPES(false);
    this.selectedRelationType = _.find(this.availableRelationTypes,
      {'name': this.relation.normalizedType(this.workPackage)})!;
  }

  /**
   * Return the normalized relation type for the work package we're viewing.
   * That is, normalize `precedes` where the work package is the `to` link.
   */
  public get normalizedRelationType() {
    var type = this.relation.normalizedType(this.workPackage);
    return this.I18n.t('js.relation_labels.' + type);
  }

  public get relationReady() {
    return this.relatedWorkPackage && this.relatedWorkPackage.$loaded;
  }

  public startDescriptionEdit() {
    this.userInputs.showDescriptionEditForm = true;
    setTimeout(() => {
      const textarea = jQuery(this.relationDescriptionTextarea.nativeElement);
      const textlen = (textarea.val() as string).length;
      // Focus and set cursor to end
      textarea.focus();

      textarea.prop('selectionStart', textlen);
      textarea.prop('selectionEnd', textlen);
    });
  }

  public handleDescriptionKey($event:JQueryEventObject) {
    if ($event.which === 27) {
      this.cancelDescriptionEdit();
    }
  }

  public cancelDescriptionEdit() {
    this.userInputs.showDescriptionEditForm = false;
    this.userInputs.newRelationText = this.relation.description || '';
  }

  public saveDescription() {
    this.wpRelations.updateRelation(
      this.relation,
      {description: this.userInputs.newRelationText})
      .then((savedRelation:RelationResource) => {
        this.relation = savedRelation;
        this.relatedWorkPackage.relatedBy = savedRelation;
        this.userInputs.showDescriptionEditForm = false;
        this.wpNotificationsService.showSave(this.relatedWorkPackage);
      });
  }

  public get showDescriptionInfo() {
    return this.userInputs.showRelationInfo || this.relation.description;
  }

  public activateRelationTypeEdit() {
    if (this.groupByWorkPackageType) {
      this.userInputs.showRelationTypesForm = true;
    }
  }

  public cancelRelationTypeEditOnEscape(evt:JQueryEventObject) {
    this.userInputs.showRelationTypesForm = false;
  }

  public saveRelationType() {
    this.wpRelations.updateRelationType(
      this.workPackage,
      this.relatedWorkPackage,
      this.relation,
      this.selectedRelationType.name)
      .then((savedRelation:RelationResource) => {
        this.wpNotificationsService.showSave(this.relatedWorkPackage);
        this.relatedWorkPackage.relatedBy = savedRelation;
        this.relation = savedRelation;

        this.userInputs.showRelationTypesForm = false;
      })
      .catch((error:any) => this.wpNotificationsService.handleRawError(error, this.workPackage));
  }

  public toggleUserDescriptionForm() {
    this.userInputs.showDescriptionEditForm = !this.userInputs.showDescriptionEditForm;
  }

  public removeRelation() {
    this.wpRelations.removeRelation(this.relation)
      .then(() => {
        this.wpCacheService.updateWorkPackage(this.relatedWorkPackage);
        this.wpNotificationsService.showSave(this.relatedWorkPackage);
      })
      .catch((err:any) => this.wpNotificationsService.handleRawError(err,
        this.relatedWorkPackage));
  }
}
