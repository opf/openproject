import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {ChangeDetectorRef, Component, ElementRef, Input, OnInit, ViewChild} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";


@Component({
  selector: 'wp-relation-row',
  templateUrl: './wp-relation-row.template.html'
})
export class WorkPackageRelationRowComponent extends UntilDestroyedMixin implements OnInit {
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
              protected notificationService:WorkPackageNotificationService,
              protected wpRelations:WorkPackageRelationsService,
              protected halEvents:HalEventsService,
              protected I18n:I18nService,
              protected cdRef:ChangeDetectorRef,
              protected PathHelper:PathHelperService) {
    super();
  }

  ngOnInit() {
    this.relation = this.relatedWorkPackage.relatedBy as RelationResource;

    this.userInputs.newRelationText = this.relation.description || '';
    this.availableRelationTypes = RelationResource.LOCALIZED_RELATION_TYPES(false);
    this.selectedRelationType = _.find(this.availableRelationTypes,
      { 'name': this.relation.normalizedType(this.workPackage) })!;

    this.wpCacheService
      .observe(this.relatedWorkPackage.id!)
      .pipe(
        this.untilDestroyed()
      ).subscribe((wp) => {
      this.relatedWorkPackage = wp;
    });
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

  public handleDescriptionKey($event:JQuery.TriggeredEvent) {
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
      { description: this.userInputs.newRelationText })
      .then((savedRelation:RelationResource) => {
        this.relation = savedRelation;
        this.relatedWorkPackage.relatedBy = savedRelation;
        this.userInputs.showDescriptionEditForm = false;
        this.notificationService.showSave(this.relatedWorkPackage);
        this.cdRef.detectChanges();
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

  public cancelRelationTypeEditOnEscape(evt:JQuery.TriggeredEvent) {
    this.userInputs.showRelationTypesForm = false;
  }

  public saveRelationType() {
    this.wpRelations.updateRelationType(
      this.workPackage,
      this.relatedWorkPackage,
      this.relation,
      this.selectedRelationType.name)
      .then((savedRelation:RelationResource) => {
        this.notificationService.showSave(this.relatedWorkPackage);
        this.relatedWorkPackage.relatedBy = savedRelation;
        this.relation = savedRelation;

        this.userInputs.showRelationTypesForm = false;
        this.cdRef.detectChanges();
      })
      .catch((error:any) => this.notificationService.handleRawError(error, this.workPackage));
  }

  public toggleUserDescriptionForm() {
    this.userInputs.showDescriptionEditForm = !this.userInputs.showDescriptionEditForm;
  }

  public removeRelation() {
    this.wpRelations.removeRelation(this.relation)
      .then(() => {
        this.halEvents.push(this.workPackage, {
          eventType: 'association',
          relatedWorkPackage: null,
          relationType: this.relation.normalizedType(this.workPackage)
        });

        this.wpCacheService.updateWorkPackage(this.relatedWorkPackage);
        this.notificationService.showSave(this.relatedWorkPackage);
      })
      .catch((err:any) => this.notificationService.handleRawError(err,
        this.relatedWorkPackage));
  }
}
