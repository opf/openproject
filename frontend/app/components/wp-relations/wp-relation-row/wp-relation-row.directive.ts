import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {
  RelationResourceInterface,
  RelationResource
} from '../../api/api-v3/hal-resources/relation-resource.service';

class WpRelationRowDirectiveController {
  public workPackage: WorkPackageResourceInterface;
  public relatedWorkPackage: WorkPackageResourceInterface;
  public relationType: string;
  public showRelationInfo:boolean = false;
  public showEditForm:boolean = false;
  public availableRelationTypes: RelationResourceInterface[];
  public selectedRelationType: RelationResourceInterface;

  public userInputs = {
    newRelationText: '',
    showDescriptionEditForm: false,
    showRelationTypesForm: false,
    showRelationInfo: false,
  };

  // Create a quasi-field object
  public fieldController = {
    active: true,
    field: {
      required: false
    }
  }

  public relation:RelationResourceInterface;
  public text: Object;

  constructor(protected $scope: ng.IScope,
              protected $element: ng.IAugmentedJQuery,
              protected $timeout:ng.ITimeoutService,
              protected $http:ng.IHttpService,
              protected wpCacheService: WorkPackageCacheService,
              protected wpNotificationsService: WorkPackageNotificationService,
              protected wpRelations: WorkPackageRelationsService,
              protected I18n:op.I18n,
              protected PathHelper: op.PathHelper) {

    this.relation = this.relatedWorkPackage.relatedBy as RelationResourceInterface;
    this.text = {
      cancel: I18n.t('js.button_cancel'),
      save: I18n.t('js.button_save'),
      removeButton: I18n.t('js.relation_buttons.remove'),
      description_label: I18n.t('js.relation_buttons.update_description'),
      toggleDescription: I18n.t('js.relation_buttons.toggle_description'),
      updateRelation: I18n.t('js.relation_buttons.update_relation'),
      placeholder: {
        description: I18n.t('js.placeholders.relation_description')
      }
    };

    this.userInputs.newRelationText = this.relation.description || '';
    this.availableRelationTypes = wpRelations.getRelationTypes(true);
    this.selectedRelationType = _.find(this.availableRelationTypes, {'name': this.relation.type}) as RelationResourceInterface;
  };

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
    this.$timeout(() => {
      var textarea = this.$element.find('.wp-relation--description-textarea');
      var textlen = textarea.val().length;
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
      this.workPackage.id,
      this.relation,
      { description: this.userInputs.newRelationText })
      .then((savedRelation:RelationResourceInterface) => {
        this.relation = savedRelation;
        this.relatedWorkPackage.relatedBy = savedRelation;
        this.userInputs.showDescriptionEditForm = false;
        this.wpNotificationsService.showSave(this.relatedWorkPackage);
      });
  }

  public get showDescriptionInfo() {
    return this.userInputs.showRelationInfo || this.relation.description;
  }

  public saveRelationType() {
    this.wpRelations.updateRelation(
      this.workPackage.id,
      this.relation,
      { type: this.selectedRelationType.name })
      .then((savedRelation:RelationResourceInterface) => {
        this.wpNotificationsService.showSave(this.relatedWorkPackage);
        this.relatedWorkPackage.relatedBy = savedRelation;
        this.relation = savedRelation;

        this.userInputs.showRelationTypesForm = false;
      });
  }

  public toggleUserDescriptionForm() {
    this.userInputs.showDescriptionEditForm = !this.userInputs.showDescriptionEditForm;
  }

  public removeRelation() {
    this.wpRelations.removeRelation(this.relation)
      .then(() => {
        this.wpCacheService.updateWorkPackage(this.relatedWorkPackage);
        this.wpNotificationsService.showSave(this.relatedWorkPackage);
        this.$timeout(() => {
          angular.element('#relation--add-relation').focus();
        });
      })
      .catch((err:any) => this.wpNotificationsService.handleErrorResponse(err, this.relatedWorkPackage));
  }
}

function WpRelationRowDirective($timeout:ng.ITimeoutService) {
  return {
    restrict:'E',
    templateUrl:'/components/wp-relations/wp-relation-row/wp-relation-row.template.html',
    scope:{
      workPackage: '=',
      groupByWorkPackageType: '=',
      relatedWorkPackage: '='
    },
    controller:WpRelationRowDirectiveController,
    controllerAs:'$ctrl',
    bindToController:true
  };
}

wpDirectivesModule.directive('wpRelationRow', WpRelationRowDirective);
